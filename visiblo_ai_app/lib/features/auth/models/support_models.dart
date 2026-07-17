import 'package:flutter/material.dart';

class SupportCategory {
  const SupportCategory({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
}

class SupportArticle {
  const SupportArticle({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.summary,
    required this.highlights,
    this.relatedRoute,
    this.relatedActionLabel,
  });

  final String id;
  final String categoryId;
  final String title;
  final String summary;
  final List<String> highlights;
  final String? relatedRoute;
  final String? relatedActionLabel;
}

class SupportTutorial {
  const SupportTutorial({
    required this.id,
    required this.title,
    required this.description,
    required this.durationLabel,
    required this.steps,
    this.relatedRoute,
    this.relatedActionLabel,
  });

  final String id;
  final String title;
  final String description;
  final String durationLabel;
  final List<String> steps;
  final String? relatedRoute;
  final String? relatedActionLabel;
}

class SupportResourceLink {
  const SupportResourceLink({
    required this.title,
    required this.subtitle,
    required this.url,
  });

  final String title;
  final String subtitle;
  final String url;
}
