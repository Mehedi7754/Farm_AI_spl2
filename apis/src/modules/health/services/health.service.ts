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

    const envKeys = process.env.GROQ_API_KEYS ? process.env.GROQ_API_KEYS.split(',').map(k => k.trim()) : [];
    const envSingleKey = process.env.GROQ_API_KEY ? [process.env.GROQ_API_KEY.trim()] : [];
    const groqApiKeys = [...new Set([...envKeys, ...envSingleKey])].filter(k => k.length > 0);

    try {
      if (imageBuffer) {
        const b64 = imageBuffer.toString('base64');
        const formData = new FormData();
        const blob = new Blob([new Uint8Array(imageBuffer)], { type: 'image/jpeg' });
        formData.append('file', blob, fileName || 'cow_symptom.jpg');
        const modelUrl = process.env.DISEASE_MODEL_URL || 'http://localhost:8080/predict';

        // Fetch vision check and model predictions in parallel for maximum speed!
        const [vRes, mRes] = await Promise.all([
          groqApiKeys.length > 0
            ? fetch('https://api.groq.com/openai/v1/chat/completions', {
                method: 'POST',
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': `Bearer ${groqApiKeys[0]}`,
                },
                body: JSON.stringify({
                  model: 'qwen/qwen3.6-27b',
                  messages: [
                    {
                      role: 'user',
                      content: [
                        { type: 'text', text: 'Analyze this image. Is there a cow, cattle, bull, ox, or calf visible? Reply strictly with YES_COW or NOT_COW. Do not write any other words.' },
                        { type: 'image_url', image_url: { url: `data:image/jpeg;base64,${b64}` } }
                      ]
                    }
                  ],
                  max_completion_tokens: 10,
                }),
              }).catch(() => null)
            : Promise.resolve(null),

          fetch(modelUrl, {
            method: 'POST',
            body: formData,
          }).catch(() => null)
        ]);

        // 1. Process Vision check output first
        if (vRes && vRes.ok) {
          const vData: any = await vRes.json();
          const vText = vData.choices?.[0]?.message?.content || '';
          if (vText.includes('NOT_COW')) {
            return {
              assessmentId: 'none',
              livestockId,
              diagnosis: 'Invalid Image',
              riskLevel: RiskLevel.NORMAL,
              recommendations: [
                'আপলোডকৃত ছবিতে কোনো গরু সনাক্ত করা যায়নি।',
                'অনুগ্রহ করে গরুর স্পষ্ট ছবি ব্যবহার করুন।'
              ],
              analysis: 'পশুর ছবি সনাক্ত করা যায়নি (No cattle detected)',
              assessedAt: new Date().toISOString(),
            };
          }
        }

        // 2. Process Model predictions output next
        if (mRes && mRes.ok) {
          const data: any = await mRes.json();
          if (data.diagnosis) {
            diagnosis = data.diagnosis;
          }
        }
      }
    } catch (err) {
      console.warn('AI service fallback engaged:', err.message);
    }

    // Determine risk level based on AI diagnosis
    if (diagnosis.toLowerCase().includes('lumpy') || diagnosis.toLowerCase().includes('foot') || diagnosis.toLowerCase().includes('lsd') || diagnosis.toLowerCase().includes('fmd')) {
      riskLevel = RiskLevel.EMERGENCY;
    } else if (diagnosis.toLowerCase().includes('healthy') || diagnosis.toLowerCase().includes('normal') || diagnosis.toLowerCase().includes('dairy cow')) {
      riskLevel = RiskLevel.NORMAL;
    } else {
      riskLevel = RiskLevel.VET_SOON;
    }

    let analysis = `শনাক্তকৃত অবস্থা: ${diagnosis}`;
    let recommendations: string[] = [
      'আক্রান্ত পশুকে সুস্থ পশুর থেকে আলাদা রাখুন।',
      'হালকা গরম পানি ও ডেটল দিয়ে ক্ষত পরিষ্কার করুন।',
      'দ্রুত উপজেলা ভেটেরিনারি চিকিৎসকের পরামর্শ নিন।'
    ];

    // Query Groq dynamically to generate super brief Bengali recommendations based on prediction result
    if (diagnosis && diagnosis !== 'No image provided for AI analysis' && groqApiKeys.length > 0) {
      const isHealthy = diagnosis.toLowerCase().includes('healthy') || diagnosis.toLowerCase().includes('normal') || diagnosis.toLowerCase().includes('dairy cow');
      if (isHealthy) {
        analysis = `পশুটি সুস্থ মনে হচ্ছে (শনাক্তকরণ: ${diagnosis})`;
        recommendations = [
          'নিয়মিত পুষ্টিকর খাদ্য ও বিশুদ্ধ পানি দিন।',
          'খামারের পরিচ্ছন্নতা বজায় রাখুন।',
          'নিয়মিত ভ্যাকসিনেশন সম্পন্ন করুন।'
        ];
      } else {
        let attempts = 0;
        let success = false;
        while (attempts < groqApiKeys.length && !success) {
          const apiKey = groqApiKeys[attempts];
          try {
            const prompt = `You are a professional veterinarian. Provide a super brief, beautifully formatted, short recommendations list in Bengali for a cow diagnosed with: "${diagnosis}". 
Your response MUST be super brief (maximum 3 bullet points, each max 10 words) and directly actionable.
Do NOT output intro, outro, or markdown markers. Output ONLY the bullet points in Bengali.`;

            const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${apiKey}`,
              },
              body: JSON.stringify({
                model: 'llama-3.3-70b-versatile',
                messages: [
                  { role: 'user', content: prompt }
                ],
                temperature: 0.5,
                max_completion_tokens: 1024,
              }),
            });

            if (res.ok) {
              const resData: any = await res.json();
              const text = resData.choices?.[0]?.message?.content || '';
              if (text) {
                const cleanedText = text.replace(/<think>[\s\S]*?(<\/think>|$)/gi, '').trim();
                const parsed = cleanedText.split('\n')
                  .map(line => line.trim().replace(/^[-*•\d\.\)\s]+/, ''))
                  .filter(line => line.length > 3);
                if (parsed.length > 0) {
                  recommendations = parsed;
                  analysis = `পশুটি ${diagnosis} রোগে আক্রান্ত হওয়ার উচ্চ ঝুঁকি রয়েছে।`;
                  success = true;
                }
              }
            }
          } catch (e) {
            console.error('Groq call failed in health diagnosis:', e.message);
          }
          attempts++;
        }
      }
    }

    let finalLivestockId = livestockId;
    try {
      const livestockExists = await this.prisma.livestock.findUnique({
        where: { id: livestockId },
      });
      if (!livestockExists) {
        const existingLivestock = await this.prisma.livestock.findFirst();
        if (existingLivestock) {
          finalLivestockId = existingLivestock.id;
        } else {
          let farmer = await this.prisma.user.findFirst({ where: { role: 'FARMER' } });
          if (!farmer) {
            farmer = await this.prisma.user.create({
              data: {
                name: 'Default Farmer',
                email: `farmer_${Date.now()}@farm.ai`,
                password: 'password123',
                role: 'FARMER',
                phoneNumber: `+88017${Math.floor(10000000 + Math.random() * 90000000)}`,
              }
            });
          }
          const newLivestock = await this.prisma.livestock.create({
            data: {
              farmerId: farmer.id,
              species: 'Cow',
              breed: 'Local',
              gender: 'MALE',
              weight: 300,
              dateOfBirth: new Date(),
            }
          });
          finalLivestockId = newLivestock.id;
        }
      }
    } catch (dbErr) {
      console.warn('Database livestock resolution fallback failed:', dbErr.message);
    }

    // Save assessment to PostgreSQL database
    const assessment = await this.prisma.healthAssessment.create({
      data: {
        livestockId: finalLivestockId,
        riskLevel,
        diagnosisNotes: `AI Diagnosis: ${diagnosis}`,
        symptoms: ['Skin Lesions', 'Swelling'],
      },
    });

    return {
      assessmentId: assessment.id,
      livestockId: finalLivestockId,
      diagnosis,
      riskLevel,
      recommendations,
      analysis,
      assessedAt: assessment.assessedAt,
    };
  }
}
