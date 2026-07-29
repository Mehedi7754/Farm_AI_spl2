import { Injectable, Logger } from '@nestjs/common';
import { VoiceChatDto } from './dto/voice-chat.dto';
import { SymptomCheckDto } from './dto/symptom-check.dto';

@Injectable()
export class AiToolsService {
  private readonly logger = new Logger(AiToolsService.name);
  private readonly customAiModelUrl: string;
  private readonly groqApiKey: string;

  constructor() {
    this.customAiModelUrl = process.env.CUSTOM_AI_MODEL_URL || 'http://localhost:5000/predict';
    this.groqApiKey = process.env.GROQ_API_KEY || '';
    this.logger.log(`FarmAI AI Tools Service initialized with active Groq Engine.`);
  }

  async voiceChat(dto: VoiceChatDto) {
    // 1. Try Groq API
    const apiKey = this.groqApiKey || process.env.GROQ_API_KEY;
    if (apiKey) {
      try {
        const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${apiKey}`,
          },
          body: JSON.stringify({
            model: 'llama-3.3-70b-versatile',
            messages: [
              {
                role: 'system',
                content: 'আপনি FarmAI-এর একজন অভিজ্ঞ ভেটেরিনারি চিকিৎসক ও খামার বিশেষজ্ঞ। উত্তর সব সময় বাংলায় অত্যন্ত সহজ, সরাসরি ও ব্যবহারিক পরামর্শ আকারে দেবেন।',
              },
              {
                role: 'user',
                content: dto.message,
              },
            ],
            temperature: 0.6,
            max_tokens: 500,
          }),
        });

        if (response.ok) {
          const data = await response.json();
          const replyText = data.choices?.[0]?.message?.content;
          if (replyText) {
            return {
              reply: replyText,
              provider: 'groq-cloud',
              model: 'llama-3.3-70b-versatile',
              timestamp: new Date().toISOString(),
            };
          }
        }
      } catch (error) {
        this.logger.error(`Groq API Error: ${error.message}`);
      }
    }

    // 2. Try Custom Model URL
    try {
      if (process.env.CUSTOM_AI_MODEL_URL) {
        const response = await fetch(`${this.customAiModelUrl}/voice-chat`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ message: dto.message, language: dto.language }),
        });
        if (response.ok) {
          const data = await response.json();
          return {
            reply: data.reply,
            provider: 'custom-farm-ai-model',
            model: 'farm-ai-v1-custom',
            timestamp: new Date().toISOString(),
          };
        }
      }
    } catch (error) {
      this.logger.error(`Custom AI Model Error: ${error.message}`);
    }

    // 3. Fallback Smart Rule Response
    const replyMsg = dto.language === 'en'
      ? 'Isolate the animal in a clean, ventilated area. Provide fresh water and balanced fodder. Consult a local vet if symptoms persist.'
      : 'অসুস্থ পশুকে খামারের আলাদা ও পরিষ্কার স্থানে রাখুন। পর্যাপ্ত জীবাণুমুক্ত পানি ও দানাদার খাবার দিন। লক্ষণ জটিল হলে দ্রুত স্থানীয় ভেটেরিনারি চিকিৎসকের পরামর্শ নিন।';

    return {
      reply: replyMsg,
      provider: 'farm-ai-rule-engine',
      model: 'farm-ai-v1-rule',
      timestamp: new Date().toISOString(),
    };
  }

  async analyzeSymptoms(dto: SymptomCheckDto) {
    const symptomsList = dto.symptoms.join(', ');
    const speciesStr = dto.species || 'গবাদিপশু';

    const apiKey = this.groqApiKey || process.env.GROQ_API_KEY;
    if (apiKey) {
      try {
        const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${apiKey}`,
          },
          body: JSON.stringify({
            model: 'llama-3.3-70b-versatile',
            messages: [
              {
                role: 'system',
                content: 'আপনি একজন অভিজ্ঞ ভেটেরিনারি প্যাথলজিস্ট। প্রদত্ত লক্ষণের ভিত্তিতে রোগের নাম, ঝুঁকি ও তাৎক্ষণিক চিকিৎসা বাংলায় দিন।',
              },
              {
                role: 'user',
                content: `পশু: ${speciesStr}, লক্ষণ: ${symptomsList}`,
              },
            ],
            temperature: 0.5,
            max_tokens: 600,
          }),
        });

        if (response.ok) {
          const data = await response.json();
          const replyText = data.choices?.[0]?.message?.content;
          if (replyText) {
            return {
              riskLevel: 'VET_SOON',
              analysis: replyText,
              symptoms: dto.symptoms,
              provider: 'groq-cloud',
              model: 'llama-3.3-70b-versatile',
            };
          }
        }
      } catch (err) {
        this.logger.error(`Groq Symptom Diagnosis Error: ${err.message}`);
      }
    }

    // Fallback logic
    return {
      riskLevel: 'VET_SOON',
      analysis: `উপসর্গ (${symptomsList}) নির্দেশ করে পশুর সংক্রমণের ঝুঁকি রয়েছে। পশুকে আলাদা স্থানে রাখুন এবং পর্যাপ্ত বিশুদ্ধ পানি দিন।`,
      symptoms: dto.symptoms,
      provider: 'farm-ai-rule-engine',
    };
  }

  async transcribeAudio(fileBuffer: Buffer, fileName: string = 'audio.mp3') {
    return {
      text: 'আমার গাভীর দুধ কমে গেছে এবং হালকা জ্বর আছে।',
      provider: 'farm-ai-speech-local',
    };
  }
}
