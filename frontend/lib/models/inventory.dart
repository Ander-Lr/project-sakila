class Inventory {
  final int? inventoryId;
  final int? filmId;
  final int? storeId;
  final bool? active;
  final String? lastUpdate;

  Inventory({
    this.inventoryId,
    this.filmId,
    this.storeId,
    this.active,
    this.lastUpdate,
  });

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      inventoryId: json['inventoryId'],
      filmId: json['filmId'],
      storeId: json['storeId'],
      active: json['active'],
      lastUpdate: json['lastUpdate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inventoryId': inventoryId,
      'filmId': filmId,
      'storeId': storeId,
      'active': active,
      'lastUpdate': lastUpdate,
    };
  }
}
