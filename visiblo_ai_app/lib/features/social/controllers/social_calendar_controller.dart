import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../onboarding/controllers/onboarding_controller.dart';
import '../models/social_engine_models.dart';
import '../services/social_api_service.dart';

class SocialCalendarController extends GetxController {
  SocialCalendarController({
    SocialApiService? socialApiService,
    OnboardingController? onboardingController,
  }) : _socialApiService = socialApiService ?? Get.find<SocialApiService>(),
       _onboardingController =
           onboardingController ?? Get.find<OnboardingController>();

  final SocialApiService _socialApiService;
  final OnboardingController _onboardingController;

  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final posts = <SocialPostInfo>[].obs;
  final errorMessage = RxnString();
  final selectedDay = Rx<DateTime>(DateTime.now());

  String get businessId =>
      _onboardingController.currentUser.value?.backendBusinessId.trim() ?? '';

  bool get hasBusinessId => businessId.isNotEmpty;

  Future<void> loadMonth(DateTime month, {bool refresh = false}) async {
    if (!hasBusinessId) {
      posts.clear();
      errorMessage.value = 'No active business selected.';
      return;
    }

    final monthStart = DateTime(month.year, month.month);
    final monthEnd = DateTime(
      month.year,
      month.month + 1,
    ).subtract(const Duration(milliseconds: 1));

    if (refresh) {
      isRefreshing.value = true;
    } else {
      isLoading.value = true;
    }
    errorMessage.value = null;

    try {
      final response = await _socialApiService.fetchPosts(
        businessId,
        startDate: monthStart,
        endDate: monthEnd,
      );
      response.sort((a, b) => postDate(a).compareTo(postDate(b)));
      posts.assignAll(response);
    } catch (error) {
      errorMessage.value = _humanizeError(error);
      if (!refresh) posts.clear();
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  DateTime postDate(SocialPostInfo post) {
    return post.scheduledAt ??
        post.publishedAt ??
        post.createdAt ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  List<SocialPostInfo> visiblePosts({
    required int statusIndex,
    required String platformFilter,
  }) {
    return posts
        .where((post) => _matchesStatus(post, statusIndex))
        .where((post) => matchesPlatform(post, platformFilter))
        .toList(growable: false);
  }

  Map<int, List<SocialPostInfo>> postsByDay({
    required int statusIndex,
    required String platformFilter,
  }) {
    final grouped = <int, List<SocialPostInfo>>{};
    for (final post in visiblePosts(
      statusIndex: statusIndex,
      platformFilter: platformFilter,
    )) {
      final date = postDate(post);
      grouped.putIfAbsent(date.day, () => <SocialPostInfo>[]).add(post);
    }
    return grouped;
  }

  List<SocialPostInfo> postsForDate(
    DateTime date, {
    required int statusIndex,
    required String platformFilter,
  }) {
    return visiblePosts(
          statusIndex: statusIndex,
          platformFilter: platformFilter,
        )
        .where((post) {
          final postTime = postDate(post);
          return postTime.year == date.year &&
              postTime.month == date.month &&
              postTime.day == date.day;
        })
        .toList(growable: false);
  }

  List<SocialPostInfo> upcomingScheduled(String platformFilter) {
    final scheduled = posts
        .where((post) => normalizeStatus(post) == 'scheduled')
        .where((post) => matchesPlatform(post, platformFilter))
        .toList();
    scheduled.sort((a, b) => postDate(a).compareTo(postDate(b)));
    return scheduled.take(5).toList(growable: false);
  }

  int countStatus(String status) {
    return posts.where((post) => normalizeStatus(post) == status).length;
  }

  int platformCount(String platform) {
    if (platform == 'all') return posts.length;
    return posts.where((post) => matchesPlatform(post, platform)).length;
  }

  bool matchesPlatform(SocialPostInfo post, String platformFilter) {
    if (platformFilter == 'all') return true;
    return postPlatforms(post).contains(platformFilter);
  }

  List<String> postPlatforms(SocialPostInfo post) {
    final rawPlatform = post.raw['platform'];
    final rawPlatforms = post.raw['platforms'];
    final values = <String>[
      ...post.platforms,
      if (rawPlatform is String) rawPlatform,
      if (rawPlatforms is List) ...rawPlatforms.whereType<String>(),
    ];
    return values
        .map((value) => value.toLowerCase().trim())
        .map((value) => value == 'linkedin' ? 'linkedin' : value)
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  String normalizeStatus(SocialPostInfo post) {
    final status = post.status.toLowerCase().trim();
    if (status.contains('fail') || status.contains('error')) return 'failed';
    if (status.contains('publish') || post.publishedAt != null) {
      return 'published';
    }
    if (status.contains('sched') || post.scheduledAt != null) {
      return 'scheduled';
    }
    return 'draft';
  }

  Color platformColor(SocialPostInfo post) {
    final platforms = postPlatforms(post);
    if (platforms.contains('instagram')) return const Color(0xFFE4408F);
    if (platforms.contains('linkedin')) return const Color(0xFF0A66C2);
    return const Color(0xFF3168FF);
  }

  String platformIconPath(SocialPostInfo post) {
    final platforms = postPlatforms(post);
    if (platforms.contains('instagram')) return 'assets/images/instagram.png';
    if (platforms.contains('linkedin')) return 'assets/images/link.png';
    return 'assets/images/facebook.png';
  }

  bool _matchesStatus(SocialPostInfo post, int statusIndex) {
    final status = normalizeStatus(post);
    return switch (statusIndex) {
      1 => status == 'scheduled',
      2 => status == 'published',
      3 => status == 'draft',
      4 => status == 'failed',
      _ => true,
    };
  }

  String _humanizeError(Object error) {
    final message = error.toString().trim();
    if (message.startsWith('Exception: ')) {
      return message.replaceFirst('Exception: ', '');
    }
    return message.isEmpty
        ? 'Something went wrong. Please try again.'
        : message;
  }
}
