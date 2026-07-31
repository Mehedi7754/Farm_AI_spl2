import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
} from '@nestjs/common';
import { VetProfilesService } from './vet-profiles.service';
import { CreateVetProfileDto } from './dto/create-vet-profile.dto';

@Controller('vet-profiles')
export class VetProfilesController {
  constructor(private readonly vetProfilesService: VetProfilesService) {}

  @Post()
  create(@Body() createVetProfileDto: CreateVetProfileDto) {
    return this.vetProfilesService.create(createVetProfileDto);
  }

  @Get()
  findAll(
    @Query('specialization') specialization?: string,
    @Query('district') district?: string,
    @Query('isAvailable') isAvailable?: string,
  ) {
    const isAvailBool = isAvailable !== undefined ? isAvailable === 'true' : undefined;
    return this.vetProfilesService.findAll({ specialization, district, isAvailable: isAvailBool });
  }

  @Get('user/:userId')
  findByUserId(@Param('userId') userId: string) {
    return this.vetProfilesService.findByUserId(userId);
  }

  @Patch('user/:userId')
  update(@Param('userId') userId: string, @Body() dto: Partial<CreateVetProfileDto>) {
    return this.vetProfilesService.update(userId, dto);
  }

  @Patch('user/:userId/availability')
  setAvailability(@Param('userId') userId: string, @Body('isAvailable') isAvailable: boolean) {
    return this.vetProfilesService.setAvailability(userId, isAvailable);
  }

  // ── Slots ──────────────────────────────────────────────────────────────────

  @Post(':vetId/slots')
  createSlots(
    @Param('vetId') vetId: string,
    @Body('slots') slots: { date: string; startTime: string; endTime: string }[],
  ) {
    return this.vetProfilesService.createSlots(vetId, slots);
  }

  @Get(':vetId/slots')
  getSlots(@Param('vetId') vetId: string, @Query('date') date?: string) {
    return this.vetProfilesService.getSlots(vetId, date);
  }

  @Patch('slots/:slotId')
  updateSlot(
    @Param('slotId') slotId: string,
    @Body() data: { startTime?: string; endTime?: string; date?: string },
  ) {
    return this.vetProfilesService.updateSlot(slotId, data);
  }

  @Delete('slots/:slotId')
  deleteSlot(@Param('slotId') slotId: string) {
    return this.vetProfilesService.deleteSlot(slotId);
  }

  // ── Reviews ────────────────────────────────────────────────────────────────

  @Post(':vetId/reviews')
  addReview(
    @Param('vetId') vetId: string,
    @Body('farmerId') farmerId: string,
    @Body('rating') rating: number,
    @Body('comment') comment?: string,
  ) {
    return this.vetProfilesService.addReview(vetId, farmerId, rating, comment);
  }
}
