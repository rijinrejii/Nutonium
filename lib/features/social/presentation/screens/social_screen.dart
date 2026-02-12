import 'package:flutter/material.dart';
import '../../domain/entities/social_post.dart';
import '../../../../shared/services/social_service.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => SocialScreenState();
}

class SocialScreenState extends State<SocialScreen> {
  final SocialService _socialService = SocialService();
  List<SocialPost> _posts = [];
  bool _isLoading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final posts = await _socialService.getFeed();
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLike(SocialPost post) async {
    final postIndex = _posts.indexWhere((p) => p.id == post.id);
    if (postIndex == -1) return;

    final updatedPost = post.copyWith(
      isLiked: !post.isLiked,
      likes: post.isLiked ? post.likes - 1 : post.likes + 1,
    );

    setState(() {
      _posts[postIndex] = updatedPost;
    });

    try {
      if (updatedPost.isLiked) {
        await _socialService.likePost(post.id);
      } else {
        await _socialService.unlikePost(post.id);
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _posts[postIndex] = post;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${post.isLiked ? 'unlike' : 'like'} post'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFeed,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredPosts = _query.isEmpty
        ? _posts
        : _posts
            .where((p) => p.content.toLowerCase().contains(_query.toLowerCase()) ||
                p.userName.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    if (filteredPosts.isEmpty) {
      return const Center(
        child: Text('No posts available'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFeed,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredPosts.length,
        itemBuilder: (context, index) {
          final post = filteredPosts[index];
          return _PostCard(
            post: post,
            onLike: () => _handleLike(post),
          );
        },
      ),
    );
  }

  void startSearch() {
    showSearch(
      context: context,
      delegate: _PostSearchDelegate(
        posts: _posts,
        onQueryChanged: (query) => setState(() => _query = query),
        onLike: _handleLike,
      ),
    );
  }
}

class _PostSearchDelegate extends SearchDelegate<String> {
  final List<SocialPost> posts;
  final ValueChanged<String> onQueryChanged;
  final Future<void> Function(SocialPost) onLike;
  String _lastReportedQuery = '';

  _PostSearchDelegate({
    required this.posts,
    required this.onQueryChanged,
    required this.onLike,
  });

  @override
  String get searchFieldLabel => 'Search posts or users';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      inputDecorationTheme: theme.inputDecorationTheme.copyWith(
        hintStyle: const TextStyle(color: Colors.white70),
      ),
      textTheme: theme.textTheme.copyWith(
        titleLarge: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: const Color(0xFF6C63FF),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    );
  }

  List<SocialPost> _filter(String query) {
    if (query.isEmpty) return posts;
    final lower = query.toLowerCase();
    return posts
        .where((p) => p.content.toLowerCase().contains(lower) ||
            p.userName.toLowerCase().contains(lower))
        .toList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    _reportQuery();
    final filtered = _filter(query);
    if (filtered.isEmpty) {
      return const Center(child: Text('No matches'));
    }
    return _buildList(filtered);
  }

  @override
  Widget buildResults(BuildContext context) {
    _reportQuery();
    final filtered = _filter(query);
    if (filtered.isEmpty) {
      return const Center(child: Text('No matches'));
    }
    return _buildList(filtered);
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        onQueryChanged('');
        close(context, '');
      },
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            onQueryChanged('');
            showSuggestions(context);
          },
        ),
    ];
  }

  Widget _buildList(List<SocialPost> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final post = items[index];
        return _PostCard(
          post: post,
          onLike: () => onLike(post),
        );
      },
    );
  }

  void _reportQuery() {
    if (_lastReportedQuery == query) return;
    _lastReportedQuery = query;
    WidgetsBinding.instance.addPostFrameCallback((_) => onQueryChanged(query));
  }
}

class _PostCard extends StatelessWidget {
  final SocialPost post;
  final VoidCallback onLike;

  const _PostCard({
    required this.post,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  backgroundImage: post.userAvatar != null
                      ? NetworkImage(post.userAvatar!)
                      : null,
                  child: post.userAvatar == null
                      ? Text(
                          post.userName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _formatTimestamp(post.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Post content
            Text(
              post.content,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
              ),
            ),

            // Post image
            if (post.imageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  post.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 50),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Actions
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: onLike,
                    child: Row(
                      children: [
                        Icon(
                          post.isLiked ? Icons.favorite : Icons.favorite_border,
                          color: post.isLiked ? Colors.red : Colors.grey[600],
                          size: 22,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.likes}',
                          style: TextStyle(
                            color: post.isLiked ? Colors.red : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.grey[600],
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.comments}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
