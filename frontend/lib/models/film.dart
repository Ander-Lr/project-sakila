class Film {
  final int? id;
  final String title;
  final String? description;
  final int? releaseYear;
  final int? languageId;
  final int? rentalDuration;
  final double? rentalRate;
  final int? length;
  final double? replacementCost;
  final String? rating;
  final String? specialFeatures;
  final bool? active;
  final List<String>? categories;
  final List<String>? actors;

  Film({
    this.id,
    required this.title,
    this.description,
    this.releaseYear,
    this.languageId,
    this.rentalDuration,
    this.rentalRate,
    this.length,
    this.replacementCost,
    this.rating,
    this.specialFeatures,
    this.active,
    this.categories,
    this.actors,
  });

  factory Film.fromJson(Map<String, dynamic> json) {
    return Film(
      id: json['id'] ?? json['filmId'],
      title: json['title'] ?? '',
      description: json['description'],
      releaseYear: json['releaseYear'],
      languageId: json['languageId'],
      rentalDuration: json['rentalDuration'],
      rentalRate: (json['rentalRate'] as num?)?.toDouble(),
      length: json['length'],
      replacementCost: (json['replacementCost'] as num?)?.toDouble(),
      rating: json['rating'],
      specialFeatures: json['specialFeatures'],
      active: json['active'] ?? json['available'],
      categories: json['categories'] != null ? List<String>.from(json['categories']) : null,
      actors: json['actors'] != null ? List<String>.from(json['actors']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'releaseYear': releaseYear,
      'languageId': languageId,
      'rentalDuration': rentalDuration,
      'rentalRate': rentalRate,
      'length': length,
      'replacementCost': replacementCost,
      'rating': rating,
      'specialFeatures': specialFeatures,
      'active': active,
      'categories': categories,
      'actors': actors,
    };
  }
}
