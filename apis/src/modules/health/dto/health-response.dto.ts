import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class HealthResponseDto {
  @ApiProperty({ example: 'apis' })
  service!: string;

  @ApiProperty({ example: 'ok' })
  status!: 'ok';

  @ApiProperty({ example: '2026-05-01T00:00:00.000Z' })
  timestamp!: string;

  @ApiPropertyOptional({ example: 'flutter-app' })
  source?: string;
}
