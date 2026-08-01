import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import { join } from 'path';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  app.useStaticAssets(join(__dirname, '..', 'uploads'), {
    prefix: '/uploads/',
  });

  app.useStaticAssets(join(__dirname, '..', 'public'), {
    prefix: '/dashboard/',
  });

  app.useStaticAssets(join(__dirname, '..', 'public'), {
    prefix: '/web/',
  });

  app.enableCors({
    origin: '*',
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true,
  });

  app.use(helmet({
    crossOriginResourcePolicy: false,
  }));

  app.enableShutdownHooks();

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: false,
    }),
  );

  const swaggerConfig = new DocumentBuilder()
    .setTitle('Farm AI APIs')
    .setDescription('HTTP gateway docs for Farm AI backend')
    .setVersion('1.0.0')
    .build();
  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('docs', app, document);

  app.connectMicroservice<MicroserviceOptions>({
    transport: Transport.TCP,
    options: {
      host: '0.0.0.0',
      port: parseInt(process.env.MS_PORT || '3006', 10),
    },
  });

  await app.startAllMicroservices();
  const port = process.env.PORT || 3000;
  await app.listen(port, '0.0.0.0');
  console.log(`FarmAI NestJS Server running live on 0.0.0.0:${port}`);
}
bootstrap();
