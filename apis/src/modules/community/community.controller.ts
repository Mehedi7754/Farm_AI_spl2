import { Controller, Get, Post, Body, Param, Query, Delete, UseInterceptors, UploadedFile } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { CommunityService } from './community.service';
import { CreatePostDto } from './dto/create-post.dto';
import { CreateCommentDto } from './dto/create-comment.dto';

@Controller('community')
export class CommunityController {
  constructor(private readonly communityService: CommunityService) {}

  @Post('upload')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: join(__dirname, '..', '..', '..', 'uploads'),
        filename: (req, file, cb) => {
          const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
          cb(null, `${uniqueSuffix}${extname(file.originalname)}`);
        },
      }),
    }),
  )
  uploadImage(@UploadedFile() file: any) {
    if (!file) return { url: null };
    return { url: `/uploads/${file.filename}` };
  }

  @Post('posts')
  createPost(@Body() dto: CreatePostDto) {
    return this.communityService.createPost(dto);
  }

  @Get('posts')
  findAllPosts(@Query('category') category?: string) {
    return this.communityService.findAllPosts(category);
  }

  @Get('posts/:id')
  findOnePost(@Param('id') id: string) {
    return this.communityService.findOnePost(id);
  }

  @Post('posts/:id/comments')
  addComment(@Param('id') id: string, @Body() dto: CreateCommentDto) {
    return this.communityService.addComment(id, dto);
  }

  @Post('posts/:id/like')
  toggleLike(@Param('id') id: string) {
    return this.communityService.toggleLike(id);
  }

  @Delete('posts/:id')
  removePost(@Param('id') id: string) {
    return this.communityService.removePost(id);
  }
}
