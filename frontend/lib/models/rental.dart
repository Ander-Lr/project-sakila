class Rental {
  final int? rentalId;
  final String? rentalDate;
  final int? inventoryId;
  final int? customerId;
  final String? returnDate;
  final int? staffId;
  final String? lastUpdate;
  
  // Extra fields for displaying in UI
  final String? filmTitle;
  final double? amount;
  final String? customerName;
  final String? staffName;
  final double? paymentAmount;
  final String? paymentMethod;
  final String? cardLast4;
  final String? transactionRef;

  Rental({
    this.rentalId,
    this.rentalDate,
    this.inventoryId,
    this.customerId,
    this.returnDate,
    this.staffId,
    this.lastUpdate,
    this.filmTitle,
    this.amount,
    this.customerName,
    this.staffName,
    this.paymentAmount,
    this.paymentMethod,
    this.cardLast4,
    this.transactionRef,
  });

  factory Rental.fromJson(Map<String, dynamic> json) {
    return Rental(
      rentalId: json['rentalId'] ?? json['id'],
      rentalDate: json['rentalDate'],
      inventoryId: json['inventoryId'],
      customerId: json['customerId'],
      returnDate: json['returnDate'],
      staffId: json['staffId'],
      lastUpdate: json['lastUpdate'],
      filmTitle: json['filmTitle'],
      amount: (json['amount'] as num?)?.toDouble(),
      customerName: json['customerName'],
      staffName: json['staffName'],
      paymentAmount: (json['paymentAmount'] as num?)?.toDouble(),
      paymentMethod: json['paymentMethod'],
      cardLast4: json['cardLast4'],
      transactionRef: json['transactionRef'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (rentalId != null) 'rentalId': rentalId,
      'rentalDate': rentalDate,
      'inventoryId': inventoryId,
      'customerId': customerId,
      'returnDate': returnDate,
      'staffId': staffId,
      'lastUpdate': lastUpdate,
      'filmTitle': filmTitle,
      'amount': amount,
      'customerName': customerName,
      'staffName': staffName,
      'paymentAmount': paymentAmount,
      'paymentMethod': paymentMethod,
      'cardLast4': cardLast4,
      'transactionRef': transactionRef,
    };
  }
}
