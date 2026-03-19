class ProductModel {
  final int productId;
  final String name;
  final String? description;
  final int categoryId;
  final double? salePrice;
  final double depoDiscount;
  final double factor;
  final int compId;
  final double discountRate;

  ProductModel({
    required this.productId,
    required this.name,
    this.description,
    required this.categoryId,
    this.salePrice,
    required this.depoDiscount,
    required this.factor,
    required this.compId,
    required this.discountRate,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      productId: json['productId'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      categoryId: json['categoryId'] as int,
      salePrice: (json['salePrice'] as num?)?.toDouble(),
      depoDiscount: (json['depoDiscount'] as num).toDouble(),
      factor: (json['factor'] as num).toDouble(),
      compId: json['compId'] as int,
      discountRate: (json['discountRate'] as num).toDouble(),
    );
  }
}
