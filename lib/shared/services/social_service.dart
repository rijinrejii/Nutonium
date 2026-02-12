import '../../features/social/domain/entities/social_post.dart';

class SocialService {
  // Mock API call - replace with your actual API endpoint
  Future<List<SocialPost>> getFeed() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Return mock data
    return [
      SocialPost(
        id: '1',
        userName: 'John Doe',
        userAvatar: null,
        content: 'Just had an amazing day at the beach! The sunset was absolutely beautiful. 🌅',
        imageUrl: 'https://picsum.photos/400/300?random=1',
        likes: 124,
        comments: 15,
        isLiked: false,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      SocialPost(
        id: '2',
        userName: 'Jane Smith',
        userAvatar: null,
        content: 'Excited to announce my new project launch! Thanks to everyone who supported me. 🚀',
        imageUrl: null,
        likes: 89,
        comments: 23,
        isLiked: true,
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      SocialPost(
        id: '3',
        userName: 'Mike Johnson',
        userAvatar: null,
        content: 'Coffee and code - the perfect combination for a productive morning! ☕💻',
        imageUrl: 'https://picsum.photos/400/300?random=2',
        likes: 256,
        comments: 42,
        isLiked: false,
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
      ),
    ];
  }

  Future<void> likePost(String postId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    // In a real app, make API call to like the post
  }

  Future<void> unlikePost(String postId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    // In a real app, make API call to unlike the post
  }
}