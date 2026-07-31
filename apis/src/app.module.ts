import { Module } from '@nestjs/common';
import { HealthModule } from './modules/health/health.module';
import { PrismaModule } from './database/prisma.module';
import { UsersModule } from './modules/users/users.module';
import { LivestockModule } from './modules/livestock/livestock.module';
import { SmartCollarsModule } from './modules/smart-collars/smart-collars.module';
import { TeleConsultationsModule } from './modules/tele-consultations/tele-consultations.module';
import { AiToolsModule } from './modules/ai-tools/ai-tools.module';
import { MapsModule } from './modules/maps/maps.module';
import { WeatherModule } from './modules/weather/weather.module';
import { VaccinationsModule } from './modules/vaccinations/vaccinations.module';
import { FinancialRecordsModule } from './modules/financial-records/financial-records.module';
import { CommunityModule } from './modules/community/community.module';
import { VetProfilesModule } from './modules/vet-profiles/vet-profiles.module';
import { WebrtcModule } from './modules/webrtc/webrtc.module';
import { ChatModule } from './modules/chat/chat.module';

@Module({
  imports: [
    HealthModule,
    PrismaModule,
    UsersModule,
    LivestockModule,
    SmartCollarsModule,
    TeleConsultationsModule,
    AiToolsModule,
    MapsModule,
    WeatherModule,
    VaccinationsModule,
    FinancialRecordsModule,
    CommunityModule,
    VetProfilesModule,
    WebrtcModule,
    ChatModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}
