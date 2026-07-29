import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { CreatePostDto } from './dto/create-post.dto';
import { CreateCommentDto } from './dto/create-comment.dto';

@Injectable()
export class CommunityService {
  constructor(private prisma: PrismaService) {}

  async createPost(dto: CreatePostDto) {
    let authorId = dto.authorId;
    if (!authorId) {
      const defaultUser = await this.prisma.user.findFirst();
      if (defaultUser) {
        authorId = defaultUser.id;
      } else {
        const newUser = await this.prisma.user.create({
          data: {
            name: 'খামারি ভাই',
            email: `farmer_${Date.now()}@farm.ai`,
            phoneNumber: `017${Math.floor(10000000 + Math.random() * 90000000)}`,
            role: 'FARMER',
          },
        });
        authorId = newUser.id;
      }
    }

    return this.prisma.communityPost.create({
      data: {
        title: dto.title,
        content: dto.content,
        category: dto.category || 'GENERAL',
        authorId,
      },
      include: { author: true, comments: { include: { author: true } } },
    });
  }

  async findAllPosts(category?: string, userId?: string) {
    const where = category && category !== 'সবগুলো' ? { category } : {};
    let posts = await this.prisma.communityPost.findMany({
      where,
      include: { author: true, comments: { include: { author: true } }, likes: true },
      orderBy: { createdAt: 'desc' },
    });

    if (posts.length === 0) {
      // Seed default initial community post if DB is empty
      const defaultUser = await this.prisma.user.findFirst() || await this.prisma.user.create({
        data: {
          name: 'করিম শেখ',
          email: 'karim@farm.ai',
          phoneNumber: '01711223344',
          role: 'FARMER',
        },
      });

      await this.prisma.communityPost.createMany({
        data: [
          {
            title: 'গরুর খুরা রোগের প্রাথমিক চিকিৎসা কি?',
            content: 'আমার ৩টি গরুর খুরা রোগ দেখা দিয়েছে। গ্রাম্য ডাক্তার দেখানো হয়েছে কিন্তু উন্নতি হচ্ছে না। কেউ কি টিপস দেবেন?',
            category: 'রোগ-বালাই',
            authorId: defaultUser.id,
          },
          {
            title: 'উন্নত জাতের পালং শাকের বীজ বিক্রয় হবে',
            content: 'খুবই উন্নত মানের শীতকালীন পালং শাকের বীজ আছে। যারা পাইকারি নিতে চান সরাসরি যোগাযোগ করুন।',
            category: 'ক্রয়-বিক্রয়',
            authorId: defaultUser.id,
          },
          {
            title: 'দুধের উৎপাদন বৃদ্ধির সহজ উপায়',
            content: 'সুষম খাবার এবং সঠিক যত্নের মাধ্যমে গরুর দুধের উৎপাদন ১৫-২০% বৃদ্ধি করা সম্ভব। আমি নিজে উপকার পেয়েছি।',
            category: 'টিপস',
            authorId: defaultUser.id,
          },
        ],
      });

      posts = await this.prisma.communityPost.findMany({
        where,
        include: { author: true, comments: { include: { author: true } }, likes: true },
        orderBy: { createdAt: 'desc' },
      });
    }

    return posts;
  }

  async findOnePost(id: string) {
    const post = await this.prisma.communityPost.findUnique({
      where: { id },
      include: { author: true, comments: { include: { author: true } }, likes: true },
    });

    if (!post) throw new NotFoundException(`Community post with ID ${id} not found`);
    return post;
  }

  async addComment(postId: string, dto: CreateCommentDto) {
    await this.findOnePost(postId);
    let authorId = dto.authorId;
    if (!authorId) {
      const defaultUser = await this.prisma.user.findFirst();
      authorId = defaultUser ? defaultUser.id : (await this.prisma.user.create({
        data: {
          name: 'খামারি ভাই',
          email: `commenter_${Date.now()}@farm.ai`,
          phoneNumber: `017${Math.floor(10000000 + Math.random() * 90000000)}`,
        },
      })).id;
    }

    return this.prisma.communityComment.create({
      data: {
        postId,
        authorId,
        content: dto.content,
      },
      include: { author: true },
    });
  }

  async toggleLike(postId: string, userId?: string) {
    await this.findOnePost(postId);

    let activeUserId = userId;
    if (!activeUserId) {
      const defaultUser = await this.prisma.user.findFirst();
      activeUserId = defaultUser ? defaultUser.id : (await this.prisma.user.create({
        data: {
          name: 'খামারি ভাই',
          email: `liker_${Date.now()}@farm.ai`,
          phoneNumber: `017${Math.floor(10000000 + Math.random() * 90000000)}`,
        },
      })).id;
    }

    const existingLike = await this.prisma.communityLike.findUnique({
      where: {
        postId_userId: {
          postId,
          userId: activeUserId,
        },
      },
    });

    if (existingLike) {
      await this.prisma.communityLike.delete({
        where: { id: existingLike.id },
      });
      await this.prisma.communityPost.update({
        where: { id: postId },
        data: { likesCount: { decrement: 1 } },
      });
      return { liked: false };
    } else {
      await this.prisma.communityLike.create({
        data: {
          postId,
          userId: activeUserId,
        },
      });
      await this.prisma.communityPost.update({
        where: { id: postId },
        data: { likesCount: { increment: 1 } },
      });
      return { liked: true };
    }
  }

  async removePost(id: string) {
    await this.findOnePost(id);
    return this.prisma.communityPost.delete({
      where: { id },
    });
  }
}
