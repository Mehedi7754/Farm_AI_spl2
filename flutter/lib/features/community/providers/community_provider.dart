import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import 'package:flutter/foundation.dart';

class CommunityNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  CommunityNotifier() : super(const AsyncValue.loading()) {
    refreshPosts();
  }

  Future<void> refreshPosts() async {
    try {
      if (!state.hasValue) {
        state = const AsyncValue.loading();
      }
      final fetched = await ApiClient.getCommunityPosts();
      
      final parsed = fetched.map((p) {
        return {
          'id': p['id']?.toString() ?? UniqueKey().toString(),
          'title': p['title']?.toString() ?? 'খামারি আপডেট',
          'content': p['content']?.toString() ?? '',
          'category': p['category']?.toString() ?? 'টিপস',
          'authorName': p['author']?['name']?.toString() ?? p['authorName']?.toString() ?? 'খামারি সদস্য',
          'authorLocation': p['author']?['location']?.toString() ?? 'ফার্ম এআই খামার',
          'isVerified': p['author']?['isDoctor'] == true,
          'likes': _parseLikesCount(p['likes'] ?? p['likesCount']),
          'isLiked': p['isLiked'] == true,
          'comments': _parseCommentsList(p['comments']),
          'imageUrl': p['imageUrl']?.toString(),
          'createdAt': 'সাম্প্রতিক পোস্ট',
        };
      }).toList();
      
      state = AsyncValue.data(parsed);
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      if (!state.hasValue) {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }

  void addOptimisticPost(Map<String, dynamic> post) {
    if (state.hasValue) {
      final currentList = state.value!;
      state = AsyncValue.data([post, ...currentList]);
    }
  }

  int _parseLikesCount(dynamic likes) {
    if (likes == null) return 0;
    if (likes is int) return likes;
    if (likes is num) return likes.toInt();
    if (likes is List) return likes.length;
    return 0;
  }

  List<Map<String, dynamic>> _parseCommentsList(dynamic comments) {
    if (comments == null) return [];
    if (comments is List) {
      return comments.map<Map<String, dynamic>>((c) {
        if (c is Map) return Map<String, dynamic>.from(c);
        return {'content': c.toString(), 'authorName': 'খামারি সদস্য'};
      }).toList();
    }
    return [];
  }
}

final communityPostsProvider = StateNotifierProvider<CommunityNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return CommunityNotifier();
});
