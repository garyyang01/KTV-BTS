/// 搜索選項類型枚舉
enum SearchOptionType {
  station,    // 車站
  attraction, // 景點
}

/// 搜索選項模型
class SearchOption {
  final String id;
  final String name;
  final String description;
  final SearchOptionType type;
  final String icon;
  final List<String> keywords;
  final Map<String, dynamic>? metadata;

  /// 車站代碼（僅適用於車站類型）
  String? get stationCode => metadata?['stationCode'] as String?;

  const SearchOption({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.icon,
    required this.keywords,
    this.metadata,
  });

  /// 從 JSON 建立 SearchOption
  factory SearchOption.fromJson(Map<String, dynamic> json) {
    return SearchOption(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: SearchOptionType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      icon: json['icon'] as String,
      keywords: List<String>.from(json['keywords'] as List),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'icon': icon,
      'keywords': keywords,
      'metadata': metadata,
    };
  }

  /// 檢查是否匹配搜索查詢
  bool matchesQuery(String query) {
    if (query.isEmpty) return true;
    
    final lowerQuery = query.toLowerCase();
    
    // 檢查名稱
    if (name.toLowerCase().contains(lowerQuery)) {
      return true;
    }
    
    // 檢查描述
    if (description.toLowerCase().contains(lowerQuery)) {
      return true;
    }
    
    // 檢查關鍵字
    return keywords.any((keyword) => 
      keyword.toLowerCase().contains(lowerQuery)
    );
  }

  /// 獲取匹配的關鍵字
  List<String> getMatchingKeywords(String query) {
    if (query.isEmpty) return [];
    
    final lowerQuery = query.toLowerCase();
    return keywords.where((keyword) => 
      keyword.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchOption && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SearchOption(id: $id, name: $name, type: $type)';
  }
}

/// 搜索選項靜態數據類
class SearchOptions {
  SearchOptions._(); // 私有構造函數，防止實例化

  /// 所有可用的搜索選項
  static const List<SearchOption> all = [
    // 車站選項
    SearchOption(
      id: 'munich_station',
      name: 'Munich Central',
      description: 'Munich Main Railway Station - Gateway to Bavaria',
      type: SearchOptionType.station,
      icon: '🚉',
      keywords: [
        'Munich',
        'München', 
        'Munich Hbf',
        'München Hauptbahnhof',
        'Munich Central',
        'Munich Main Station',
        '慕尼黑',
        '慕尼黑中央車站',
        'Мюнхен',
        'ミュンヘン',
        '뮌헨',
      ],
      metadata: {
        'country': 'Germany',
        'city': 'Munich',
        'stationCode': 'MUC',
        'coordinates': {'lat': 48.1408, 'lng': 11.5581},
      },
    ),

    SearchOption(
      id: 'fuessen_station',
      name: 'Füssen Station',
      description: 'Gateway to Neuschwanstein Castle and the Alps',
      type: SearchOptionType.station,
      icon: '🚂',
      keywords: [
        'Füssen',
        'Fussen',
        '福森',
        'Bahnhof Füssen',
        'Füssen Bahnhof',
        'フュッセン',
        '퓌센',
        'Фюссен',
      ],
      metadata: {
        'country': 'Germany',
        'city': 'Füssen',
        'stationCode': 'FUS',
        'coordinates': {'lat': 47.5707, 'lng': 10.7016},
      },
    ),

    SearchOption(
      id: 'florence_station',
      name: 'Florence SMN',
      description: 'Firenze Santa Maria Novella - Heart of Renaissance',
      type: SearchOptionType.station,
      icon: '🚄',
      keywords: [
        'Florence',
        'Firenze',
        'Florenz',
        '佛羅倫斯',
        'Firenze S. M. Novella',
        'Firenze SMN',
        'Florence SMN',
        'Firenze Centrale',
        '佛羅倫斯中央車站',
        'Santa Maria Novella',
        'フィレンツェ',
        '피렌체',
        'Флоренция',
      ],
      metadata: {
        'country': 'Italy',
        'city': 'Florence',
        'stationCode': 'FLR',
        'coordinates': {'lat': 43.7766, 'lng': 11.2480},
      },
    ),

    SearchOption(
      id: 'milan_station',
      name: 'Milano Centrale',
      description: 'Milan Central Station - Fashion Capital Gateway',
      type: SearchOptionType.station,
      icon: '🚅',
      keywords: [
        'Milan',
        'Milano',
        'Milano Centrale',
        '米蘭',
        '米蘭中央車站',
        'Milan Central',
        'Mailand',
        'ミラノ',
        '밀라노',
        'Милан',
      ],
      metadata: {
        'country': 'Italy',
        'city': 'Milan',
        'stationCode': 'MIL',
        'coordinates': {'lat': 45.4869, 'lng': 9.2037},
      },
    ),

    // 景點選項
    SearchOption(
      id: 'neuschwanstein',
      name: 'Neuschwanstein Castle',
      description: 'Fairy-tale castle in the Bavarian Alps',
      type: SearchOptionType.attraction,
      icon: '🏰',
      keywords: [
        '新天鵝堡',
        '新天鹅堡',
        'Neuschwanstein',
        'Neuschwanstein Castle',
        'Schloss Neuschwanstein',
        '노이슈반슈타인성',
        'Château de Neuschwanstein',
        'ノイシュヴァンシュタイン城',
        'Нойшванштайн',
        'Castello di Neuschwanstein',
      ],
      metadata: {
        'country': 'Germany',
        'city': 'Schwangau',
        'ticketPrice': {'adult': 19, 'child': 1},
        'coordinates': {'lat': 47.5576, 'lng': 10.7498},
        'openingHours': '9:00-18:00',
      },
    ),

    SearchOption(
      id: 'uffizi',
      name: 'Uffizi Gallery',
      description: 'World-renowned art museum in Florence',
      type: SearchOptionType.attraction,
      icon: '🎨',
      keywords: [
        '烏菲齊美術館',
        '烏菲茲美術館',
        'Uffizi',
        'Uffizi Gallery',
        'Galleria degli Uffizi',
        'Galerie des Offices',
        'Галерея Уффици',
        'ウフィツィ美術館',
        '우피치 미술관',
        'Galería Uffizi',
      ],
      metadata: {
        'country': 'Italy',
        'city': 'Florence',
        'ticketPrice': {'adult': 24, 'child': 0},
        'coordinates': {'lat': 43.7687, 'lng': 11.2569},
        'openingHours': '8:15-18:30',
      },
    ),
  ];

  /// 根據類型篩選選項
  static List<SearchOption> getByType(SearchOptionType type) {
    return all.where((option) => option.type == type).toList();
  }

  /// 根據 ID 查找選項
  static SearchOption? findById(String id) {
    try {
      return all.firstWhere((option) => option.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 搜索選項
  static List<SearchOption> search(String query) {
    if (query.isEmpty) return all;
    
    return all.where((option) => option.matchesQuery(query)).toList();
  }

  /// 獲取所有車站
  static List<SearchOption> get stations => getByType(SearchOptionType.station);

  /// 獲取所有景點
  static List<SearchOption> get attractions => getByType(SearchOptionType.attraction);

  /// 獲取熱門選項（前 4 個）
  static List<SearchOption> get popular => all.take(4).toList();

  /// 根據國家分組
  static Map<String, List<SearchOption>> groupByCountry() {
    final Map<String, List<SearchOption>> grouped = {};
    
    for (final option in all) {
      final country = option.metadata?['country'] as String? ?? 'Unknown';
      grouped.putIfAbsent(country, () => []).add(option);
    }
    
    return grouped;
  }

  /// 獲取支援的語言關鍵字統計
  static Map<String, int> getLanguageStats() {
    final Map<String, int> stats = {};
    
    for (final option in all) {
      for (final keyword in option.keywords) {
        // 簡單的語言檢測邏輯
        if (RegExp(r'[\u4e00-\u9fff]').hasMatch(keyword)) {
          stats['Chinese'] = (stats['Chinese'] ?? 0) + 1;
        } else if (RegExp(r'[\u3040-\u309f\u30a0-\u30ff]').hasMatch(keyword)) {
          stats['Japanese'] = (stats['Japanese'] ?? 0) + 1;
        } else if (RegExp(r'[\uac00-\ud7af]').hasMatch(keyword)) {
          stats['Korean'] = (stats['Korean'] ?? 0) + 1;
        } else if (RegExp(r'[\u0400-\u04ff]').hasMatch(keyword)) {
          stats['Russian'] = (stats['Russian'] ?? 0) + 1;
        } else {
          stats['Latin'] = (stats['Latin'] ?? 0) + 1;
        }
      }
    }
    
    return stats;
  }
}

/// 搜索結果類
class SearchResult {
  final SearchOption option;
  final List<String> matchingKeywords;
  final double relevanceScore;

  const SearchResult({
    required this.option,
    required this.matchingKeywords,
    required this.relevanceScore,
  });

  /// 建立搜索結果
  factory SearchResult.fromOption(SearchOption option, String query) {
    final matchingKeywords = option.getMatchingKeywords(query);
    
    // 計算相關性分數
    double score = 0.0;
    final lowerQuery = query.toLowerCase();
    
    // 名稱完全匹配得分最高
    if (option.name.toLowerCase() == lowerQuery) {
      score += 100.0;
    } else if (option.name.toLowerCase().startsWith(lowerQuery)) {
      score += 80.0;
    } else if (option.name.toLowerCase().contains(lowerQuery)) {
      score += 60.0;
    }
    
    // 關鍵字匹配得分
    for (final keyword in matchingKeywords) {
      if (keyword.toLowerCase() == lowerQuery) {
        score += 90.0;
      } else if (keyword.toLowerCase().startsWith(lowerQuery)) {
        score += 70.0;
      } else {
        score += 50.0;
      }
    }
    
    // 描述匹配得分
    if (option.description.toLowerCase().contains(lowerQuery)) {
      score += 30.0;
    }
    
    return SearchResult(
      option: option,
      matchingKeywords: matchingKeywords,
      relevanceScore: score,
    );
  }
}

/// 搜索服務類
class SearchService {
  SearchService._();

  /// 執行搜索
  static List<SearchResult> performSearch(String query, {
    SearchOptionType? filterType,
    int? limit,
  }) {
    if (query.isEmpty) {
      final options = filterType != null 
          ? SearchOptions.getByType(filterType)
          : SearchOptions.all;
      
      return options.map((option) => SearchResult(
        option: option,
        matchingKeywords: [],
        relevanceScore: 0.0,
      )).take(limit ?? options.length).toList();
    }

    // 搜索並建立結果
    List<SearchResult> results = [];
    
    for (final option in SearchOptions.all) {
      if (filterType != null && option.type != filterType) continue;
      
      if (option.matchesQuery(query)) {
        results.add(SearchResult.fromOption(option, query));
      }
    }

    // 按相關性排序
    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

    // 限制結果數量
    if (limit != null && results.length > limit) {
      results = results.take(limit).toList();
    }

    return results;
  }

  /// 獲取建議搜索
  static List<String> getSuggestions(String query, {int limit = 5}) {
    final results = performSearch(query, limit: limit * 2);
    final suggestions = <String>[];

    for (final result in results) {
      // 添加選項名稱
      if (!suggestions.contains(result.option.name)) {
        suggestions.add(result.option.name);
      }

      // 添加匹配的關鍵字
      for (final keyword in result.matchingKeywords) {
        if (!suggestions.contains(keyword) && suggestions.length < limit) {
          suggestions.add(keyword);
        }
      }

      if (suggestions.length >= limit) break;
    }

    return suggestions.take(limit).toList();
  }
}
