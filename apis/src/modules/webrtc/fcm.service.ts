import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { initializeApp, getApps, App, cert } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import * as path from 'path';
import * as fs from 'fs';

@Injectable()
export class FcmService implements OnModuleInit {
  private readonly logger = new Logger(FcmService.name);
  private app: App | null = null;

  onModuleInit() {
    try {
      const serviceAccountPath = path.join(process.cwd(), 'firebase-service-account.json');
      if (!fs.existsSync(serviceAccountPath)) {
        this.logger.warn('firebase-service-account.json not found — FCM disabled');
        return;
      }
      const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));

      if (getApps().length === 0) {
        this.app = initializeApp({ credential: cert(serviceAccount) });
      } else {
        this.app = getApps()[0];
      }
      this.logger.log('Firebase Admin SDK initialized ✓');
    } catch (e) {
      this.logger.error('Failed to initialize Firebase Admin SDK', e);
    }
  }

  async sendCallNotification(opts: {
    fcmToken: string;
    callerName: string;
    roomId: string;
    consultationId: string;
  }): Promise<void> {
    if (!this.app) {
      this.logger.warn('FCM not initialized — skipping push notification');
      return;
    }

    const { fcmToken, callerName, roomId, consultationId } = opts;

    try {
      await getMessaging(this.app).send({
        token: fcmToken,
        android: {
          priority: 'high',
          notification: {
            channelId: 'incoming_call',
            title: '📞 ইনকামিং ভিডিও কল',
            body: `ডাঃ ${callerName} আপনাকে কল করছেন`,
            sound: 'default',
          },
        },
        data: {
          type: 'INCOMING_CALL',
          roomId,
          consultationId,
          callerName,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        notification: {
          title: '📞 ইনকামিং ভিডিও কল',
          body: `ডাঃ ${callerName} আপনাকে কল করছেন`,
        },
      });
      this.logger.log(`Call FCM sent to ${fcmToken.substring(0, 20)}...`);
    } catch (e: any) {
      this.logger.error('FCM send failed', e?.message);
    }
  }

  async sendGenericNotification(opts: {
    fcmToken: string;
    title: string;
    body: string;
    data?: Record<string, string>;
  }): Promise<void> {
    if (!this.app) return;
    try {
      await getMessaging(this.app).send({
        token: opts.fcmToken,
        android: { priority: 'high' },
        notification: { title: opts.title, body: opts.body },
        data: opts.data ?? {},
      });
    } catch (e: any) {
      this.logger.error('FCM generic send failed', e?.message);
    }
  }
}
