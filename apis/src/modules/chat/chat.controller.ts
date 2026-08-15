import { Controller, Post, Get, Patch, Body, Param, Query } from '@nestjs/common';
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

  @Get('unread/:userId')
  async getUnreadSummary(@Param('userId') userId: string) {
    return this.chatService.getUnreadSummary(userId);
  }

  @Patch('mark-read')
  async markAsRead(
    @Body('receiverId') receiverId: string,
    @Body('senderId') senderId: string,
  ) {
    return this.chatService.markAsRead(receiverId, senderId);
  }
}
