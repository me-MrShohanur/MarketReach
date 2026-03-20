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

  // ── Cart fields — set when user saves in _AddProductDetailSheet ──────────
  // These are NOT from the API — they are filled by the user in the detail sheet
  final double cartQty; // what user typed in Quantity field
  final double cartRate; // what user typed in Rate field
  final double cartDiscount; // what user typed in Discount field (flat amount)
  final double cartNetAmount; // calculated: (cartQty * cartRate) - cartDiscount
  final String cartNotes; // what user typed in Notes field

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
    // Cart fields default to 0 — populated when added to cart
    this.cartQty = 0,
    this.cartRate = 0,
    this.cartDiscount = 0,
    this.cartNetAmount = 0,
    this.cartNotes = '',
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

  // copyWith — creates a new ProductModel with updated cart fields
  // Used in _AddProductDetailSheet when user taps Save
  ProductModel copyWithCart({
    required double cartQty,
    required double cartRate,
    required double cartDiscount,
    required double cartNetAmount,
    required String cartNotes,
  }) {
    return ProductModel(
      productId: productId,
      name: name,
      description: description,
      categoryId: categoryId,
      salePrice: salePrice,
      depoDiscount: depoDiscount,
      factor: factor,
      compId: compId,
      discountRate: discountRate,
      cartQty: cartQty,
      cartRate: cartRate,
      cartDiscount: cartDiscount,
      cartNetAmount: cartNetAmount,
      cartNotes: cartNotes,
    );
  }
}
