import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_typography.dart';
import '../controllers/support_controller.dart';
import '../models/support_models.dart';
import '../widgets/auth_layout.dart';
import '../widgets/auth_navigation_shell.dart';

class SupportView extends GetView<SupportController> {
  const SupportView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthNavigationShell(
      currentTab: AuthTab.account,
      backgroundColor: const Color(0xFFF7FBFC),
      child: Obx(() {
        final categories = controller.filteredCategories;
        final articles = controller.searchResults;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWideLayout = constraints.maxWidth >= 1040;
            final maxWidth = isWideLayout ? 1220.0 : 760.0;

            final mainColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopBar(
                  onBack: handleAuthBack,
                  onClearSearch: controller.clearQuery,
                  hasActiveQuery: controller.query.value.trim().isNotEmpty,
                ),
                const SizedBox(height: 12),
                if (controller.errorMessage.value != null) ...[
                  _FeedbackBanner(
                    message: controller.errorMessage.value!,
                    isError: true,
                    onDismiss: controller.clearError,
                  ),
                  const SizedBox(height: 12),
                ],
                if (controller.infoMessage.value != null) ...[
                  _FeedbackBanner(
                    message: controller.infoMessage.value!,
                    onDismiss: controller.clearInfo,
                  ),
                  const SizedBox(height: 12),
                ],
                _SearchHeroCard(controller: controller),
                const SizedBox(height: 12),
                _SectionCard(
                  eyebrow: 'Browse by category',
                  title: 'Support topics',
                  description:
                      'Search the knowledge base or open a category to explore the most relevant guides.',
                  child: categories.isEmpty
                      ? _EmptySearchState(
                          query: controller.query.value,
                          onClear: controller.clearQuery,
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: constraints.maxWidth >= 720
                                    ? 2
                                    : 1,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: constraints.maxWidth >= 720
                                    ? 1.38
                                    : 1.55,
                              ),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            return _CategoryCard(
                              category: category,
                              articleCount: controller.articleCountFor(
                                category.id,
                              ),
                              onTap: () => _showCategorySheet(
                                context,
                                controller,
                                category,
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  eyebrow: controller.query.value.trim().isEmpty
                      ? 'Popular articles'
                      : 'Search results',
                  title: controller.query.value.trim().isEmpty
                      ? 'Most requested guides'
                      : 'Matching help content',
                  description: controller.query.value.trim().isEmpty
                      ? 'Open the articles people use most often when setting up or troubleshooting a workspace.'
                      : 'These articles match your current search.',
                  child: articles.isEmpty
                      ? _EmptySearchState(
                          query: controller.query.value,
                          onClear: controller.clearQuery,
                        )
                      : Column(
                          children: [
                            for (
                              var index = 0;
                              index < articles.length;
                              index += 1
                            ) ...[
                              _ArticleRow(
                                article: articles[index],
                                onTap: () => _showArticleSheet(
                                  context,
                                  controller,
                                  articles[index],
                                ),
                              ),
                              if (index != articles.length - 1)
                                const SizedBox(height: 10),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  eyebrow: 'Video tutorials',
                  title: 'Quick walkthroughs',
                  description:
                      'Open short guided flows for the most common setup and growth tasks.',
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: constraints.maxWidth >= 960
                          ? 3
                          : constraints.maxWidth >= 640
                          ? 2
                          : 1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: constraints.maxWidth >= 640
                          ? 1.08
                          : 1.18,
                    ),
                    itemCount: controller.tutorials.length,
                    itemBuilder: (context, index) {
                      final tutorial = controller.tutorials[index];
                      return _TutorialCard(
                        tutorial: tutorial,
                        onTap: () =>
                            _showTutorialSheet(context, controller, tutorial),
                      );
                    },
                  ),
                ),
              ],
            );

            final sideColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ContactCard(controller: controller),
                const SizedBox(height: 12),
                _ResourcesCard(controller: controller),
              ],
            );

            final content = isWideLayout
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 8, child: mainColumn),
                      const SizedBox(width: 18),
                      Expanded(flex: 5, child: sideColumn),
                    ],
                  )
                : controller.isPlanActivationRequest
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sideColumn,
                      const SizedBox(height: 12),
                      mainColumn,
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      mainColumn,
                      const SizedBox(height: 12),
                      sideColumn,
                    ],
                  );

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(
                AuthViewSpacing.pageHorizontal,
                12,
                AuthViewSpacing.pageHorizontal,
                24,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: content,
                  ),
                ),
              ],
            );
          },
        );
      }),
    );
  }

  Future<void> _showCategorySheet(
    BuildContext context,
    SupportController controller,
    SupportCategory category,
  ) async {
    final matchingArticles = controller.articles
        .where((article) => article.categoryId == category.id)
        .toList(growable: false);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _DetailSheet(
          title: category.title,
          subtitle: category.description,
          child: Column(
            children: [
              for (
                var index = 0;
                index < matchingArticles.length;
                index += 1
              ) ...[
                _ArticleRow(
                  article: matchingArticles[index],
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _showArticleSheet(
                      context,
                      controller,
                      matchingArticles[index],
                    );
                  },
                ),
                if (index != matchingArticles.length - 1)
                  const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _showArticleSheet(
    BuildContext context,
    SupportController controller,
    SupportArticle article,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _DetailSheet(
          title: article.title,
          subtitle: article.summary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...article.highlights.map(
                (highlight) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BulletPoint(text: highlight),
                ),
              ),
              if ((article.relatedRoute ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    controller.openRoute(article.relatedRoute!);
                  },
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(
                    article.relatedActionLabel ?? 'Open related screen',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0E7490),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _showTutorialSheet(
    BuildContext context,
    SupportController controller,
    SupportTutorial tutorial,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _DetailSheet(
          title: tutorial.title,
          subtitle: tutorial.description,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8F9),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFC9EEF1)),
                ),
                child: Text(
                  tutorial.durationLabel,
                  style: AppTypography.label(
                    fontSize: 11,
                    color: const Color(0xFF0E7490),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ...tutorial.steps.map(
                (step) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BulletPoint(text: step),
                ),
              ),
              if ((tutorial.relatedRoute ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    controller.openRoute(tutorial.relatedRoute!);
                  },
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  label: Text(
                    tutorial.relatedActionLabel ?? 'Open related screen',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0E7490),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onBack,
    required this.onClearSearch,
    required this.hasActiveQuery,
  });

  final VoidCallback onBack;
  final VoidCallback onClearSearch;
  final bool hasActiveQuery;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AuthShellBackButton(onTap: onBack),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Help & Support',
                style: AppTypography.section(
                  fontSize: 30,
                  color: const Color(0xFF002B5C),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Get help, browse guides, and contact the Visiblo team from one place.',
                style: AppTypography.body(
                  fontSize: 14,
                  color: const Color(0xFF5F7088),
                ),
              ),
            ],
          ),
        ),
        if (hasActiveQuery) ...[
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onClearSearch,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Clear'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0E7490),
              side: const BorderSide(color: Color(0xFFC9EEF1)),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SearchHeroCard extends StatelessWidget {
  const _SearchHeroCard({required this.controller});

  final SupportController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFD7EEF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12002B5C),
            blurRadius: 34,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 6,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF002B5C),
                  Color(0xFF179CA3),
                  Color(0xFF9BDDE2),
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Text(
                  'How can we help you?',
                  style: AppTypography.section(
                    fontSize: 28,
                    color: const Color(0xFF002B5C),
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Search our knowledge base, open walkthroughs, or contact support directly.',
                  style: AppTypography.body(
                    fontSize: 14,
                    color: const Color(0xFF66778F),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: controller.searchController,
                  decoration: InputDecoration(
                    hintText: 'Search articles, tutorials, and setup help...',
                    hintStyle: AppTypography.body(
                      fontSize: 14,
                      color: const Color(0xFF92A0B4),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF7A8AA1),
                    ),
                    suffixIcon: controller.query.value.trim().isEmpty
                        ? null
                        : IconButton(
                            onPressed: controller.clearQuery,
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: const Color(0xFFF9FCFD),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Color(0xFFD9E7EF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Color(0xFFD9E7EF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(
                        color: Color(0xFF179CA3),
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    required this.message,
    required this.onDismiss,
    this.isError = false,
  });

  final String message;
  final VoidCallback onDismiss;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final accent = isError ? const Color(0xFFE24B4B) : const Color(0xFF179CA3);
    final background = isError
        ? const Color(0xFFFFF1F1)
        : const Color(0xFFEAF9FB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            color: accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body(
                fontSize: 14,
                color: const Color(0xFF29415E),
              ),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            splashRadius: 18,
            icon: Icon(Icons.close_rounded, color: accent),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCE8EF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: AppTypography.label(
                    fontSize: 11,
                    color: const Color(0xFF179CA3),
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: AppTypography.card(
                    fontSize: 22,
                    color: const Color(0xFF002B5C),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.body(
                    fontSize: 13.5,
                    color: const Color(0xFF6B7C93),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEDF3F6)),
          Padding(padding: const EdgeInsets.all(18), child: child),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.articleCount,
    required this.onTap,
  });

  final SupportCategory category;
  final int articleCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFDCE8EF)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(category.icon, color: const Color(0xFF179CA3)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.title,
                    style: AppTypography.body(
                      fontSize: 15,
                      color: const Color(0xFF002B5C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(
                      fontSize: 12.8,
                      color: const Color(0xFF6B7C93),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$articleCount articles',
                      style: AppTypography.label(
                        fontSize: 11,
                        color: const Color(0xFF475569),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF7A8AA1)),
          ],
        ),
      ),
    );
  }
}

class _ArticleRow extends StatelessWidget {
  const _ArticleRow({required this.article, required this.onTap});

  final SupportArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFBFDFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE1EAF0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.description_outlined,
                size: 18,
                color: Color(0xFF179CA3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: AppTypography.body(
                      fontSize: 14.5,
                      color: const Color(0xFF002B5C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(
                      fontSize: 12.8,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: Color(0xFF7A8AA1),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialCard extends StatelessWidget {
  const _TutorialCard({required this.tutorial, required this.onTap});

  final SupportTutorial tutorial;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFDCE8EF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F9),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.play_circle_fill_rounded,
                color: Color(0xFF179CA3),
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              tutorial.title,
              style: AppTypography.body(
                fontSize: 15,
                color: const Color(0xFF002B5C),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tutorial.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(
                fontSize: 12.8,
                color: const Color(0xFF64748B),
              ),
            ),
            const Spacer(),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tutorial.durationLabel,
                    style: AppTypography.label(
                      fontSize: 11,
                      color: const Color(0xFF475569),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF7A8AA1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.controller});

  final SupportController controller;

  @override
  Widget build(BuildContext context) {
    final activationRequest = controller.isPlanActivationRequest;
    return _SectionCard(
      eyebrow: 'Contact support',
      title: activationRequest ? 'Need to activate a plan?' : 'Need more help?',
      description: activationRequest
          ? 'Contact our support team to request activation for your account.'
          : 'The Visiblo team is ready to help with setup, account, content, and growth questions.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FBFC),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFDCE8EF)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF8F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Color(0xFF179CA3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Support contact',
                        style: AppTypography.body(
                          fontSize: 14.5,
                          color: const Color(0xFF002B5C),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        SupportController.supportEmail,
                        style: AppTypography.body(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: controller.isLaunching.value
                ? null
                : controller.startLiveChat,
            icon: controller.isLaunching.value
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            label: const Text('Start Live Chat'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0E7490),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: controller.isLaunching.value
                ? null
                : controller.submitTicket,
            icon: const Icon(Icons.mail_outline_rounded),
            label: Text(
              activationRequest ? 'Request Activation' : 'Submit Ticket',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0E7490),
              side: const BorderSide(color: Color(0xFFC9EEF1)),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourcesCard extends StatelessWidget {
  const _ResourcesCard({required this.controller});

  final SupportController controller;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      eyebrow: 'Resources',
      title: 'External links',
      description:
          'Open the official Visiblo web resources referenced around the dashboard ecosystem.',
      child: Column(
        children: [
          for (
            var index = 0;
            index < controller.resources.length;
            index += 1
          ) ...[
            _ResourceTile(
              resource: controller.resources[index],
              onTap: () => controller.openResource(controller.resources[index]),
            ),
            if (index != controller.resources.length - 1)
              const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ResourceTile extends StatelessWidget {
  const _ResourceTile({required this.resource, required this.onTap});

  final SupportResourceLink resource;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDCE8EF)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: Color(0xFF179CA3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    style: AppTypography.body(
                      fontSize: 14.5,
                      color: const Color(0xFF002B5C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    resource.subtitle,
                    style: AppTypography.body(
                      fontSize: 12.6,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.query, required this.onClear});

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFDFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No matches found',
            style: AppTypography.body(
              fontSize: 15,
              color: const Color(0xFF002B5C),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'We could not find help content for "$query". Try a broader term or clear the current search.',
            style: AppTypography.body(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Clear search'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0E7490),
              side: const BorderSide(color: Color(0xFFC9EEF1)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 54,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6DEE9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: AppTypography.card(
                  fontSize: 22,
                  color: const Color(0xFF17345D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: AppTypography.body(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  const _BulletPoint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF179CA3),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTypography.body(
              fontSize: 14,
              color: const Color(0xFF29415E),
            ),
          ),
        ),
      ],
    );
  }
}
