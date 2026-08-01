import { Injectable, Logger } from '@nestjs/common';
import { VoiceChatDto } from './dto/voice-chat.dto';
import { SymptomCheckDto } from './dto/symptom-check.dto';
import { MedicineInfoDto } from './dto/medicine-info.dto';
import { Groq } from 'groq-sdk';

@Injectable()
export class AiToolsService {
  private readonly logger = new Logger(AiToolsService.name);
  private readonly customAiModelUrl: string;
  private readonly groqApiKeys: string[];
  private currentGroqKeyIndex: number = 0;

  constructor() {
    this.customAiModelUrl = process.env.CUSTOM_AI_MODEL_URL || 'http://localhost:5000/predict';
    
    // Combine any keys from environment
    const envKeys = process.env.GROQ_API_KEYS ? process.env.GROQ_API_KEYS.split(',').map(k => k.trim()) : [];
    const envSingleKey = process.env.GROQ_API_KEY ? [process.env.GROQ_API_KEY.trim()] : [];
    
    // Merge and deduplicate all keys from environment variables only
    this.groqApiKeys = [...new Set([...envKeys, ...envSingleKey])].filter(k => k.length > 0);
    
    this.logger.log(`FarmAI AI Tools Service initialized with ${this.groqApiKeys.length} active Groq API Keys for rotation.`);
  }

  async voiceChat(dto: VoiceChatDto) {
    // 1. Try Groq API with Rotation
    if (this.groqApiKeys.length > 0) {
      let attempts = 0;
      while (attempts < this.groqApiKeys.length) {
        const apiKey = this.groqApiKeys[this.currentGroqKeyIndex];
        try {
          const groq = new Groq({ apiKey });
          const chatCompletion = await groq.chat.completions.create({
            messages: [
              {
                role: 'system',
                content: 'আপনি FarmAI-এর একজন অভিজ্ঞ ভেটেরিনারি চিকিৎসক। উত্তর অত্যন্ত সংক্ষিপ্ত (সর্বোচ্চ ২-৩ বাক্য) এবং সরাসরি দেবেন। কোনো অপ্রয়োজনীয় কথা বলবেন অ্যাকশন নেবেন না। Do NOT output <thought> or <tool_call> tags. Do NOT use markdown. Provide ONLY the spoken response.',
              },
              {
                role: 'user',
                content: dto.message,
              },
            ],
            model: 'qwen/qwen3.6-27b',
            temperature: 0.6,
            max_completion_tokens: 4000,
            top_p: 0.95,
            stream: false,
            stop: null,
          });

          let replyText = chatCompletion.choices[0]?.message?.content || '';
          
          // Handle R1 style <think> models
          if (replyText.includes('</think>')) {
             replyText = replyText.split('</think>')[1];
          } else if (replyText.includes('<think>')) {
             // Model got cut off while thinking
             replyText = "আমি এখন একটু ব্যস্ত, দয়া করে আপনার প্রশ্নটি আবার একটু সহজ করে বলুন।";
          }

          // Sanitize any remaining XML-like tags
          replyText = replyText.replace(/<[^>]*>/g, '').trim();

          if (replyText) {
            return {
              reply: replyText,
              provider: 'groq-cloud',
              model: 'qwen/qwen3.6-27b',
              timestamp: new Date().toISOString(),
            };
          }
          break; // if successful but empty reply, break out to try other fallbacks
        } catch (error) {
          if (error?.status === 429 || (error.message && error.message.includes('429'))) {
             this.logger.warn(`Groq rate limit hit on key index ${this.currentGroqKeyIndex}. Rotating to next key.`);
             this.currentGroqKeyIndex = (this.currentGroqKeyIndex + 1) % this.groqApiKeys.length;
             attempts++;
          } else {
             this.logger.error(`Groq API Error: ${error.message}`);
             break; // break out of rotation loop for non rate-limit errors
          }
        }
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

    if (this.groqApiKeys.length > 0) {
      let attempts = 0;
      while (attempts < this.groqApiKeys.length) {
        const apiKey = this.groqApiKeys[this.currentGroqKeyIndex];
        try {
          const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${apiKey}`,
            },
            body: JSON.stringify({
              model: 'qwen/qwen3.6-27b',
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
              max_completion_tokens: 4000,
            }),
          });

          if (response.status === 429) {
             this.logger.warn(`Groq rate limit hit on key index ${this.currentGroqKeyIndex} in analyzeSymptoms. Rotating to next key.`);
             this.currentGroqKeyIndex = (this.currentGroqKeyIndex + 1) % this.groqApiKeys.length;
             attempts++;
             continue; // try the next key
          }

          if (response.ok) {
            const data = await response.json();
            const replyText = data.choices?.[0]?.message?.content;
            if (replyText) {
              return {
                riskLevel: 'VET_SOON',
                analysis: replyText,
                symptoms: dto.symptoms,
                provider: 'groq-cloud',
                model: 'qwen/qwen3.6-27b',
              };
            }
          }
          break; // break if successful but bad parsing, or non-429 error code
        } catch (err) {
          this.logger.error(`Groq Symptom Diagnosis Error: ${err.message}`);
          break;
        }
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

  async getMedicineInfo(dto: MedicineInfoDto) {
    const systemPrompt = `You are an expert veterinary pharmacologist.
Your strict requirement is to output ONLY valid JSON format. Do not include any conversational text outside the JSON.
ONLY provide real, scientifically validated, real-world veterinary medicines and pharmacological data.
Do NOT use placeholders (like medicine_a, company_b, etc.).
Do NOT make up fake medicines or data.
Do NOT use ellipses (...) or truncate the JSON. Output the FULL JSON array.

CRITICAL INSTRUCTIONS:
1. ALL output values (except maybe standard medicine names/companies) MUST be written in BENGALI (বাংলা).
2. Keep all descriptions VERY BRIEF and SHORT to use fewer tokens.
3. Provide MAXIMUM 3 medicines per response.

Return ONLY a JSON array of objects.
Each object must have exactly these keys:
- name (string)
- group (string)
- company (string)
- type (string)
- species (string)
- uses (string)
- dosage (string)
- sideEffects (string)
- warning (string)

The JSON array must be at the root. Example:
[
  {
    "name": "Renamycin 100",
    "group": "অক্সিটেট্রাসাইক্লিন",
    "company": "Renata Limited",
    "type": "ইনজেকশন",
    "species": "গরু, ছাগল",
    "uses": "ব্রড স্পেকট্রাম অ্যান্টিবায়োটিক।",
    "dosage": "১০ কেজি ওজনের জন্য ১ মিলি।",
    "sideEffects": "ইনজেকশনের স্থানে ব্যথা।",
    "warning": "ডাক্তারের পরামর্শ নিন।"
  }
]`;

    let userPrompt = `Give me medicine info for: ${dto.query}`;
    if (dto.disease) userPrompt += `\nDisease: ${dto.disease}`;
    if (dto.symptoms) userPrompt += `\nSymptoms: ${dto.symptoms}`;
    if (dto.species) userPrompt += `\nSpecies: ${dto.species}`;

    if (this.groqApiKeys.length > 0) {
      let attempts = 0;
      while (attempts < this.groqApiKeys.length) {
        const apiKey = this.groqApiKeys[this.currentGroqKeyIndex];
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
                { role: 'system', content: systemPrompt },
                { role: 'user', content: userPrompt },
              ],
              temperature: 0.3,
              max_completion_tokens: 4096,
            }),
          });

          if (response.status === 429) {
             this.logger.warn(`Groq rate limit hit on key index ${this.currentGroqKeyIndex} in getMedicineInfo. Rotating to next key.`);
             this.currentGroqKeyIndex = (this.currentGroqKeyIndex + 1) % this.groqApiKeys.length;
             attempts++;
             continue; // try the next key
          }

          if (response.ok) {
            const data = await response.json();
            let replyText = data.choices?.[0]?.message?.content || '';

            // Strip <think> blocks if present
            replyText = replyText.replace(/<think>[\s\S]*?(<\/think>|$)/gi, '').trim();

            // Find JSON array bounds
            const firstBracket = replyText.indexOf('[');
            const lastBracket = replyText.lastIndexOf(']');

            if (firstBracket !== -1 && lastBracket !== -1 && lastBracket > firstBracket) {
              const jsonStr = replyText.substring(firstBracket, lastBracket + 1);
              try {
                const parsed = JSON.parse(jsonStr);
                if (Array.isArray(parsed) && parsed.length > 0) {
                  return { medicines: parsed, provider: 'groq-cloud', model: 'qwen/qwen3.6-27b' };
                }
              } catch (e) {
                this.logger.error(`Failed to parse extracted JSON in getMedicineInfo: ${e.message}`);
                this.logger.error(`JSON string was: ${jsonStr}`);
              }
            } else {
              this.logger.error(`No JSON array brackets found in text: ${replyText}`);
            }
          }
          break; // break if successful but bad parsing, or non-429 error code
        } catch (err) {
          this.logger.error(`Groq Medicine Info Error: ${err.message}`);
          break;
        }
      }
    }

    // Fallback if all fails
    return { medicines: [] };
  }

  async transcribeAudio(fileBuffer: Buffer, fileName: string = 'audio.mp3') {
    return {
      text: 'আমার গাভীর দুধ কমে গেছে এবং হালকা জ্বর আছে।',
      provider: 'farm-ai-speech-local',
    };
  }
}
