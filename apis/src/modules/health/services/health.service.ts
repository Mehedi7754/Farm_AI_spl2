import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { HealthRequestDto } from '../dto/health-request.dto';
import { HealthResponseDto } from '../dto/health-response.dto';
import { PrismaService } from '../../../database/prisma.service';
import { RiskLevel } from '@prisma/client';

@Injectable()
export class HealthService {
  constructor(private prisma: PrismaService) {}

  getHealth(payload?: HealthRequestDto): HealthResponseDto {
    return {
      service: 'apis',
      status: 'ok',
      timestamp: new Date().toISOString(),
      source: payload?.source,
    };
  }

  async diagnoseCowDisease(livestockId: string, imageBuffer?: Buffer, fileName?: string) {
    let diagnosis = 'No image provided for AI analysis';
    let riskLevel: RiskLevel = RiskLevel.NORMAL;

    try {
      if (imageBuffer) {
        // 1. Primary: Call AWS SageMaker Real-time Endpoint
        try {
          const { SageMakerRuntimeClient, InvokeEndpointCommand } = await import('@aws-sdk/client-sagemaker-runtime');
          
          const sagemakerClient = new SageMakerRuntimeClient({ region: 'us-east-1' });
          
          const response = await sagemakerClient.send(new InvokeEndpointCommand({
            EndpointName: 'alvee-farmai-cow-disease-endpoint',
            ContentType: 'image/jpeg',
            Body: imageBuffer
          }));
          
          if (response.Body) {
            const responseText = Buffer.from(response.Body).toString('utf-8');
            const result = JSON.parse(responseText);
            if (result && result.diagnosis) {
              diagnosis = result.diagnosis;
            } else if (result && result.error) {
              throw new Error(result.error);
            }
          }
        } catch (awsErr) {
          console.warn('AWS Real-time Endpoint failed, falling back to local Rest API:', awsErr.message);
          // 2. Fallback: Local / Gradio REST API
          const formData = new FormData();
          const blob = new Blob([new Uint8Array(imageBuffer)], { type: 'image/jpeg' });
          formData.append('file', blob, fileName || 'cow_symptom.jpg');
 
          const modelUrl = process.env.DISEASE_MODEL_URL || 'http://localhost:8080/predict';
          const response = await fetch(modelUrl, {
            method: 'POST',
            body: formData,
          });
 
          if (response.ok) {
            const data: any = await response.json();
            if (data.diagnosis) {
              diagnosis = data.diagnosis;
            }
          }
        }
      }
    } catch (err) {
      console.warn('AI service fallback engaged:', err.message);
    }

    // Determine risk level based on AI diagnosis
    if (diagnosis.toLowerCase().includes('lumpy') || diagnosis.toLowerCase().includes('foot')) {
      riskLevel = RiskLevel.EMERGENCY;
    } else if (diagnosis.toLowerCase().includes('healthy') || diagnosis.toLowerCase().includes('normal')) {
      riskLevel = RiskLevel.NORMAL;
    } else {
      riskLevel = RiskLevel.VET_SOON;
    }

    // Save assessment to PostgreSQL database
    const assessment = await this.prisma.healthAssessment.create({
      data: {
        livestockId,
        riskLevel,
        diagnosisNotes: `AI Diagnosis: ${diagnosis}`,
        symptoms: ['Skin Lesions', 'Swelling'],
      },
    });

    return {
      assessmentId: assessment.id,
      livestockId,
      diagnosis,
      riskLevel,
      recommendations: [
        'Isolate infected animal immediately to prevent spread.',
        'Apply antiseptic ointment on skin lesions.',
        'Contact nearby field veterinarian for treatment.',
      ],
      assessedAt: assessment.assessedAt,
    };
  }
}
