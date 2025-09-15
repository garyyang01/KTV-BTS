/// Bundle information model for tour packages
class BundleInfo {
  final String id;
  final String name;
  final String intro;
  final String highlights;
  final double priceEur;
  final List<String> images;
  final String location;
  
  const BundleInfo({
    required this.id,
    required this.name,
    required this.intro,
    required this.highlights,
    required this.priceEur,
    required this.images,
    required this.location,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'intro': intro,
      'highlights': highlights,
      'price_eur': priceEur.toString(),
      'images': images,
      'location': location,
    };
  }

  /// Create from JSON
  factory BundleInfo.fromJson(Map<String, dynamic> json) {
    return BundleInfo(
      id: json['_id'] as String,
      name: json['name'] as String,
      intro: json['intro'] as String,
      highlights: json['highlights'] as String? ?? '',
      priceEur: double.tryParse(json['price_eur']?.toString() ?? '0') ?? 0.0,
      images: (json['images'] as List<dynamic>?)?.cast<String>() ?? [],
      location: json['location'] as String,
    );
  }

  /// Get formatted price string
  String get formattedPrice => '€${priceEur.toStringAsFixed(2)}';

  /// Get primary image URL (first image in the list)
  String? get primaryImageUrl => images.isNotEmpty ? images.first : null;

  /// Check if bundle has highlights
  bool get hasHighlights => highlights.isNotEmpty;

  @override
  String toString() {
    return 'BundleInfo(id: $id, name: $name, priceEur: $priceEur, location: $location)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BundleInfo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
