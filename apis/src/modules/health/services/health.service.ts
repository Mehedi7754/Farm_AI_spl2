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
        // 1. Primary: Call AWS SageMaker Async Endpoint
        try {
          const { SageMakerRuntimeClient, InvokeEndpointAsyncCommand } = await import('@aws-sdk/client-sagemaker-runtime');
          const { S3Client, PutObjectCommand, GetObjectCommand } = await import('@aws-sdk/client-s3');
          
          const sagemakerClient = new SageMakerRuntimeClient({ region: 'us-east-1' });
          const s3Client = new S3Client({ region: 'us-east-1' });
          
          const bucketName = 'sagemaker-us-east-1-942909611360';
          const fileKey = `async-inputs/diag-${Date.now()}-${fileName || 'cow.jpg'}`;
          
          // A. Upload image to S3 for SageMaker Async input
          await s3Client.send(new PutObjectCommand({
            Bucket: bucketName,
            Key: fileKey,
            Body: imageBuffer,
            ContentType: 'image/jpeg'
          }));
          
          const inputS3Uri = `s3://${bucketName}/${fileKey}`;
          
          // B. Trigger Async SageMaker endpoint
          const response = await sagemakerClient.send(new InvokeEndpointAsyncCommand({
            EndpointName: 'farmai-cow-disease-gpu-endpoint',
            ContentType: 'image/jpeg',
            InputLocation: inputS3Uri
          }));
          
          const outputS3Uri = response.OutputLocation; // e.g. s3://bucket/async-outputs/id.out
          if (!outputS3Uri) {
            throw new Error('No OutputLocation returned from SageMaker');
          }
          const outputKey = outputS3Uri.replace(`s3://${bucketName}/`, '');
          
          // C. Poll S3 output bucket (up to 30 attempts, 2-sec intervals)
          let polledResult = null;
          for (let attempt = 0; attempt < 30; attempt++) {
            await new Promise((res) => setTimeout(res, 2000));
            try {
              const s3Obj = await s3Client.send(new GetObjectCommand({
                Bucket: bucketName,
                Key: outputKey
              }));
              if (s3Obj.Body) {
                const responseText = await s3Obj.Body.transformToString();
                const result = JSON.parse(responseText);
                if (result && result.diagnosis) {
                  polledResult = result.diagnosis;
                  break;
                }
              }
            } catch (s3Err) {
              // NoSuchKey or not ready yet, continue polling
            }
          }
          
          if (polledResult) {
            diagnosis = polledResult;
          } else {
            throw new Error('Async prediction timeout');
          }
        } catch (awsErr) {
          console.warn('AWS Async Endpoint failed, falling back to local Rest API:', awsErr.message);
          // 2. Fallback: Local / Gradio REST API
          const formData = new FormData();
          const blob = new Blob([new Uint8Array(imageBuffer)], { type: 'image/jpeg' });
          formData.append('file', blob, fileName || 'cow_symptom.jpg');
 
          const response = await fetch('http://localhost:8080/predict', {
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
