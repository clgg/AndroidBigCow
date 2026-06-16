class TechCategory {
  const TechCategory({
    required this.id,
    required this.label,
    required this.description,
    required this.languages,
  });

  final String id;
  final String label;
  final String description;
  final List<TechLanguage> languages;

  factory TechCategory.fromJson(Map<String, Object?> json) {
    final rawLanguages = json['languages'];
    return TechCategory(
      id: json['id'] as String,
      label: json['label'] as String,
      description: json['description'] as String? ?? '',
      languages: rawLanguages is List
          ? rawLanguages
              .cast<Map<String, Object?>>()
              .map(TechLanguage.fromJson)
              .toList(growable: false)
          : const [],
    );
  }
}

class TechLanguage {
  const TechLanguage({
    required this.id,
    required this.label,
    required this.description,
  });

  final String id;
  final String label;
  final String description;

  factory TechLanguage.fromJson(Map<String, Object?> json) {
    return TechLanguage(
      id: json['id'] as String,
      label: json['label'] as String,
      description: json['description'] as String? ?? '',
    );
  }
}

class SelectedTechStack {
  const SelectedTechStack({required this.categoryId, required this.languageId});

  final String categoryId;
  final String languageId;

  String get storageValue => '$categoryId/$languageId';

  static SelectedTechStack? fromStorage(String? value) {
    if (value == null || value.isEmpty || !value.contains('/')) {
      return null;
    }
    final parts = value.split('/');
    if (parts.length != 2) {
      return null;
    }
    if (parts[0].isEmpty || parts[1].isEmpty) {
      return null;
    }
    return SelectedTechStack(categoryId: parts[0], languageId: parts[1]);
  }
}

class TechStackCatalog {
  static const categories = [
    TechCategory(
      id: 'frontend',
      label: '前端',
      description: 'Web、跨端、小程序与现代前端工程',
      languages: [
        TechLanguage(
            id: 'javascript', label: 'JavaScript', description: '浏览器基础与工程化'),
        TechLanguage(
            id: 'typescript', label: 'TypeScript', description: '类型系统与大型项目实践'),
        TechLanguage(id: 'react', label: 'React', description: '组件、状态与性能优化'),
        TechLanguage(id: 'vue', label: 'Vue', description: '响应式、组合式 API 与生态'),
        TechLanguage(id: 'miniapp', label: '小程序', description: '微信/支付宝等小程序开发'),
      ],
    ),
    TechCategory(
      id: 'backend',
      label: '后端',
      description: '服务端语言、架构、数据库与分布式系统',
      languages: [
        TechLanguage(
            id: 'java-backend', label: 'Java', description: 'JVM、Spring 与服务治理'),
        TechLanguage(id: 'go', label: 'Go', description: '并发、微服务与云原生'),
        TechLanguage(
            id: 'python', label: 'Python', description: 'Web、脚本、数据与自动化'),
        TechLanguage(
            id: 'nodejs', label: 'Node.js', description: '服务端 JS 与高并发 IO'),
        TechLanguage(id: 'rust', label: 'Rust', description: '系统编程与高可靠服务'),
      ],
    ),
    TechCategory(
      id: 'client',
      label: '客户端',
      description: '移动端、桌面端、跨平台与系统能力',
      languages: [
        TechLanguage(
            id: 'android',
            label: 'Android',
            description: 'Kotlin/Java、Framework 与性能优化'),
        TechLanguage(
            id: 'ios', label: 'iOS', description: 'Swift、UIKit/SwiftUI 与系统能力'),
        TechLanguage(
            id: 'harmonyos', label: '鸿蒙', description: 'ArkTS、ArkUI 与鸿蒙生态'),
        TechLanguage(
            id: 'flutter', label: 'Flutter', description: 'Dart、渲染、跨平台工程'),
        TechLanguage(
            id: 'react-native',
            label: 'React Native',
            description: '原生桥接与跨端体验'),
      ],
    ),
    TechCategory(
      id: 'ai',
      label: 'AI',
      description: '大模型、应用开发、算法工程与 AI Infra',
      languages: [
        TechLanguage(
            id: 'llm-app',
            label: 'LLM 应用',
            description: 'Prompt、RAG、Agent 与评测'),
        TechLanguage(
            id: 'machine-learning', label: '机器学习', description: '训练、特征、模型与指标'),
        TechLanguage(
            id: 'deep-learning', label: '深度学习', description: '神经网络、训练优化与推理'),
        TechLanguage(
            id: 'ai-infra', label: 'AI Infra', description: '向量库、推理服务与工程化'),
      ],
    ),
  ];

  static TechCategory? categoryById(String id) {
    for (final category in categories) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }

  static TechLanguage? languageById(String categoryId, String languageId) {
    final category = categoryById(categoryId);
    if (category == null) {
      return null;
    }
    for (final language in category.languages) {
      if (language.id == languageId) {
        return language;
      }
    }
    return null;
  }

  static SelectedTechStack? find(String categoryId, String languageId) {
    return languageById(categoryId, languageId) == null
        ? null
        : SelectedTechStack(categoryId: categoryId, languageId: languageId);
  }

  static String labelFor(
    SelectedTechStack stack, [
    List<TechCategory> catalog = TechStackCatalog.categories,
  ]) {
    final category = _categoryById(catalog, stack.categoryId);
    final language = _languageById(catalog, stack.categoryId, stack.languageId);
    if (category == null || language == null) {
      return '未选择';
    }
    return '${category.label} / ${language.label}';
  }

  static TechCategory? _categoryById(List<TechCategory> source, String id) {
    for (final category in source) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }

  static TechLanguage? _languageById(
    List<TechCategory> source,
    String categoryId,
    String languageId,
  ) {
    final category = _categoryById(source, categoryId);
    if (category == null) {
      return null;
    }
    for (final language in category.languages) {
      if (language.id == languageId) {
        return language;
      }
    }
    return null;
  }
}
