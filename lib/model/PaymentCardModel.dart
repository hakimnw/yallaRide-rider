class PaymentCardModel {
  int? id;
  String? cardHolderName;
  String? cardNumber;
  String? expiryDate;
  String? cvv;
  int? userId;
  String? createdAt;
  String? updatedAt;

  PaymentCardModel({
    this.id,
    this.cardHolderName,
    this.cardNumber,
    this.expiryDate,
    this.cvv,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentCardModel.fromJson(Map<String, dynamic> json) {
    return PaymentCardModel(
      id: json['id'],
      cardHolderName: json['card_holder_name'],
      cardNumber: json['card_number'],
      expiryDate: json['expiry_date'],
      cvv: json['cvv'],
      userId: json['user_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['card_holder_name'] = cardHolderName;
    data['card_number'] = cardNumber;
    data['expiry_date'] = expiryDate;
    data['cvv'] = cvv;
    data['user_id'] = userId;

    if (id != null) data['id'] = id;
    if (createdAt != null) data['created_at'] = createdAt;
    if (updatedAt != null) data['updated_at'] = updatedAt;

    return data;
  }
}
