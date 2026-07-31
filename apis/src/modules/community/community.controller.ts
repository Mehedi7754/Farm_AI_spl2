import { Controller, Get, Post, Body, Param, Query, Delete, UseInterceptors, UploadedFile, Req, BadRequestException } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { CommunityService } from './community.service';
import { CreatePostDto } from './dto/create-post.dto';
import { CreateCommentDto } from './dto/create-comment.dto';
const multerS3 = require('multer-s3');
import { S3Client } from '@aws-sdk/client-s3';
import { extname } from 'path';

const s3Client = new S3Client({ region: 'us-east-1' });

@Controller('community')
export class CommunityController {
  constructor(private readonly communityService: CommunityService) {}

  @Post('upload')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: multerS3({
        s3: s3Client,
        bucket: 'farmai-community-uploads-v1',
        acl: 'public-read',
        contentType: multerS3.AUTO_CONTENT_TYPE,
        key: function (req, file, cb) {
          const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
          cb(null, `${uniqueSuffix}${extname(file.originalname)}`);
        },
      }),
    }),
  )
  uploadImage(@UploadedFile() file: any) {
    if (!file) {
      throw new BadRequestException('File is required');
    }
    return { url: file.location };
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
