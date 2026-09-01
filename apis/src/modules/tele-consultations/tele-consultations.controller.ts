import { Controller, Get, Post, Body, Patch, Param, Query, Delete } from '@nestjs/common';
import { TeleConsultationsService } from './tele-consultations.service';

@Controller('tele-consultations')
export class TeleConsultationsController {
  constructor(private readonly svc: TeleConsultationsService) {}

  // Farmer books a slot
  @Post('book')
  book(
    @Body('farmerId') farmerId: string,
    @Body('vetId') vetId: string,
    @Body('slotId') slotId: string,
    @Body('notes') notes?: string,
  ) {
    return this.svc.book(farmerId, vetId, slotId, notes);
  }

  // Vet accepts
  @Patch(':id/accept')
  accept(@Param('id') id: string) {
    return this.svc.accept(id);
  }

  // Vet rejects
  @Patch(':id/reject')
  reject(@Param('id') id: string) {
    return this.svc.reject(id);
  }

  // Mark completed
  @Patch(':id/complete')
  complete(@Param('id') id: string, @Body('prescription') prescription?: string) {
    return this.svc.complete(id, prescription);
  }

  // Start call
  @Patch(':id/start-call')
  startCall(@Param('id') id: string) {
    return this.svc.startCall(id);
  }

  // My consultations (farmer or vet)
  @Get('my/:userId')
  findMy(@Param('userId') userId: string, @Query('role') role: 'FARMER' | 'VET') {
    return this.svc.findMyConsultations(userId, role);
  }

  @Get()
  findAll(@Query('farmerId') farmerId?: string, @Query('vetId') vetId?: string) {
    return this.svc.findAll(farmerId, vetId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.svc.findOne(id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: any) {
    return this.svc.update(id, dto);
  }

  @Patch(':id/cancel')
  cancelPatch(@Param('id') id: string, @Query('cancelledBy') cancelledBy?: string) {
    return this.svc.cancel(id, cancelledBy);
  }

  @Post(':id/cancel')
  cancelPost(@Param('id') id: string, @Query('cancelledBy') cancelledBy?: string) {
    return this.svc.cancel(id, cancelledBy);
  }

  @Delete(':id/permanent')
  deletePermanent(@Param('id') id: string) {
    return this.svc.deletePermanent(id);
  }

  @Delete(':id')
  deleteDirect(@Param('id') id: string) {
    return this.svc.deletePermanent(id);
  }
}
