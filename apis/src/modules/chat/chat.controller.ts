import { Controller, Post, Get, Body, Param, Query } from '@nestjs/common';
import { ChatService } from './chat.service';

@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Post('send')
  async sendMessage(
    @Body('senderId') senderId: string,
    @Body('receiverId') receiverId: string,
    @Body('content') content: string,
  ) {
    return this.chatService.sendMessage(senderId, receiverId, content);
  }

  @Get('history/:otherUserId')
  async getChatHistory(
    @Query('userId') userId: string,
    @Param('otherUserId') otherUserId: string,
  ) {
    return this.chatService.getChatHistory(userId, otherUserId);
  }

  @Get('list')
  async getChatList(@Query('userId') userId: string) {
    return this.chatService.getChatList(userId);
  }
}
