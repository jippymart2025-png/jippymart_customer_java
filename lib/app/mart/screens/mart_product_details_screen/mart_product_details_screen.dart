import 'dart:async';
import 'dart:convert';
import 'package:jippymart_customer/app/cart_screen/cart_screen.dart';
import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/home_provider.dart';
import 'package:jippymart_customer/app/mart/mart_home_screen/provider/mart_provider.dart';
import 'package:jippymart_customer/app/mart/screens/mart_brand_products_screen/mart_brand_products_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/cart_product_model.dart';
import 'package:jippymart_customer/models/mart_brand_model.dart';
import 'package:jippymart_customer/models/mart_item_model.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/color_const.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class MartProductDetailsScreen extends StatefulWidget {
  final dynamic product;

  const MartProductDetailsScreen({super.key, required this.product});

  @override
  State<MartProductDetailsScreen> createState() =>
      _MartProductDetailsScreenState();
}

class _MartProductDetailsScreenState extends State<MartProductDetailsScreen>
    with WidgetsBindingObserver {
  int quantity = 1;
  int selectedImageIndex = 0;
  bool isInCart = false;
  int cartQuantity = 0;
  Timer? _cartStatusTimer;
  Timer? _loadingTimeoutTimer;
  MartBrandModel? brandData;
  Stream<List<MartItemModel>>? _similarProductsStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkCartStatus();
    _fetchDeliverySettings();
    _fetchBrandData();
    _initializeSimilarProductsStream();
    _cartStatusTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (mounted) {
        _checkCartStatus();
      }
    });
  }

  /// Initialize the similar products stream (by-category when available, else one-time all-products)
  void _initializeSimilarProductsStream() {
    final controller = Provider.of<MartProvider>(context, listen: false);
    final product = widget.product;
    if (product.categoryID != null && product.categoryID!.isNotEmpty) {
      _similarProductsStream = controller.streamSimilarProducts(
        categoryId: product.categoryID!,
        subcategoryId: product.subcategoryID is String
            ? product.subcategoryID as String?
            : null,
        excludeProductId: product.id,
        isAvailable: true,
        limit: 10,
      );
    } else {
      _similarProductsStream = controller.streamAllProducts(
        excludeProductId: product.id,
        isAvailable: true,
        limit: 10,
      );
    }
  }

  /// Fetch delivery settings from Firestore
  void _fetchDeliverySettings() {
    try {
      final martController = Provider.of<MartProvider>(context, listen: false);
      martController.fetchDeliverySettings();
    } catch (e) {
      print('Error fetching delivery settings: $e');
    }
  }

  /// Fetch brand data from Firestore
  Future<void> _fetchBrandData() async {
    if (widget.product.brandID != null && widget.product.brandID!.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse(
            '${AppConst.baseUrl}mobile/brands/${widget.product.brandID}',
          ),
          headers: await getHeaders(),
        );

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          if (jsonResponse['success'] == true) {
            setState(() {
              brandData = MartBrandModel.fromJson(
                jsonResponse['data']['brand'],
              );
            });
          }
        } else {
          print('Error fetching brand data: ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching brand data: $e');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cartStatusTimer?.cancel();
    _loadingTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh cart status when app becomes active
      _checkCartStatus();
    }
  }

  void _checkCartStatus() {
    try {
      print(
        '[CART STATUS] Checking cart status for product: ${widget.product.id}',
      );
      print('[CART STATUS] Total cart items: ${HomeProvider.cartItem.length}');

      // Find the product in the global cart list
      final foundCartItem = HomeProvider.cartItem.firstWhere(
        (item) => item.id == widget.product.id,
        orElse: () => CartProductModel(),
      );

      print(
        '[CART STATUS] Found cart item: ${foundCartItem.id}, quantity: ${foundCartItem.quantity}',
      );

      if (foundCartItem.id != null &&
          foundCartItem.quantity != null &&
          foundCartItem.quantity! > 0) {
        print(
          '[CART STATUS] Product is in cart with quantity: ${foundCartItem.quantity}',
        );
        setState(() {
          isInCart = true;
          cartQuantity = foundCartItem.quantity!;
        });
      } else {
        print('[CART STATUS] Product is not in cart');
        setState(() {
          isInCart = false;
          cartQuantity = 0;
        });
      }
    } catch (e) {
      print('[CART STATUS] Error checking cart status: $e');
      setState(() {
        isInCart = false;
        cartQuantity = 0;
      });
    }
  }

  void _refreshCartStatus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCartStatus();
    });
  }

  void _navigateToBrandProducts(String? brandID, String brandTitle) {
    if (brandID != null && brandID.isNotEmpty) {
      Get.to(
        () => MartBrandProductsScreen(brandID: brandID, brandTitle: brandTitle),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Brand information not available'),
          backgroundColor: Colors.orange.shade600,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCartStatus();
    });
    return WillPopScope(
      onWillPop: () async {
        _checkCartStatus();
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F6FF),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: const Color(0xFFF6F6FF),
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.black87),
                ),
                onPressed: () => Get.back(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    // Product Image
                    PageView.builder(
                      onPageChanged: (index) {
                        setState(() {
                          selectedImageIndex = index;
                        });
                      },
                      itemCount: _getProductImages().length,
                      itemBuilder: (context, index) {
                        final imageUrl = _getProductImages()[index];
                        return imageUrl != 'https://via.placeholder.com/400x400'
                            ? NetworkImageWidget(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                errorWidget: Container(
                                  color: Colors.grey[100],
                                  child: Center(
                                    child: SvgPicture.asset(
                                      'assets/icons/ic_picture_one.svg',
                                      width: 80,
                                      height: 80,
                                      colorFilter: ColorFilter.mode(
                                        Colors.grey[400]!,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                color: Colors.grey[100],
                                child: Center(
                                  child: SvgPicture.asset(
                                    'assets/icons/ic_picture_one.svg',
                                    width: 80,
                                    height: 80,
                                    colorFilter: ColorFilter.mode(
                                      Colors.grey[400]!,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              );
                      },
                    ),

                    // Image Indicators
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _getProductImages().length,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selectedImageIndex == index
                                  ? const Color(0xFF5D56F3)
                                  : Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Product Details
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      widget.product.name ?? 'Product Name',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Brand Information
                    if (widget.product.brandTitle != null &&
                        widget.product.brandTitle!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          _navigateToBrandProducts(
                            widget.product.brandID,
                            widget.product.brandTitle!,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child:
                                    brandData?.logoUrl != null &&
                                        brandData!.logoUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: NetworkImageWidget(
                                          imageUrl: brandData!.logoUrl,
                                          width: 24,
                                          height: 24,
                                          fit: BoxFit.contain,
                                          errorWidget: Icon(
                                            Icons.business,
                                            size: 24,
                                            color: const Color(0xFFE91E63),
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.business,
                                        size: 24,
                                        color: const Color(0xFFE91E63),
                                      ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Brand: ${widget.product.brandTitle}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE91E63),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Icon(
                              //   Icons.arrow_forward_ios,
                              //   size: 12,
                              //   color: const Color(0xFFE91E63).withOpacity(0.7),
                              // ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    // Price and Rating Section
                    Row(
                      children: [
                        // Price Section
                        Row(
                          children: [
                            Text(
                              '₹${widget.product.disPrice ?? widget.product.price}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                            if (widget.product.disPrice != null &&
                                widget.product.disPrice! <
                                    widget.product.price) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${((widget.product.price - widget.product.disPrice!) / widget.product.price * 100).round()}% Off',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '₹${widget.product.price}',
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Colors.red,
                                  color: Colors.red[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),

                        const Spacer(),

                        // Rating Section
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${widget.product.reviewSum ?? 0}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${widget.product.reviewCount ?? 0})',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    const SizedBox(height: 16),

                    // Available options (when product has variants)
                    if (widget.product.has_options == true &&
                        widget.product.options != null &&
                        widget.product.options!.isNotEmpty) ...[
                      const Text(
                        'Available options',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...(widget.product.options!.map((option) {
                        final hasDiscount = option['original_price'] != null &&
                            option['price'] != null &&
                            option['original_price'] > option['price'];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: (option['image']?.toString().isNotEmpty == true)
                                      ? NetworkImageWidget(
                                          imageUrl: option['image'].toString(),
                                          width: 56,
                                          height: 56,
                                          fit: BoxFit.cover,
                                        )
                                      : NetworkImageWidget(
                                          imageUrl: widget.product.photo,
                                          width: 56,
                                          height: 56,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      option['option_title']?.toString() ??
                                          option['option_subtitle']?.toString() ??
                                          'Option',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          '₹${option['price']?.toString() ?? '0'}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        if (hasDiscount) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            '₹${option['original_price']?.toString() ?? '0'}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              decoration: TextDecoration.lineThrough,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Material(
                                color: ColorConst.orangeLight,
                                borderRadius: BorderRadius.circular(10),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => _addOptionToCart(option),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    child: Text(
                                      'ADD',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      })),
                      const SizedBox(height: 16),
                    ],

                    // Delivery Information
                    Row(
                      children: [
                        const Icon(
                          Icons.flash_on,
                          color: Colors.purple,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Estimated Delivery Time: 6 mins',
                            style: TextStyle(
                              color: Colors.purple[400],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Service Guarantees
                    Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.block,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'No Return Or Exchange',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.flash_on,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Fast Delivery',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    const SizedBox(height: 10),

                    // Product Details (using description if available)
                    if (widget.product.description != null &&
                        widget.product.description!.isNotEmpty) ...[
                      const Text(
                        'Product Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.product.description!,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Product Information
                    if (widget.product.brand != null ||
                        widget.product.weight != null ||
                        widget.product.expiryDate != null) ...[
                      const Text(
                        'Product Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (widget.product.brand != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 100,
                                child: Text(
                                  'Brand:',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  widget.product.brand!,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (widget.product.weight != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 100,
                                child: Text(
                                  'Weight:',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  widget.product.weight!,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (widget.product.expiryDate != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 100,
                                child: Text(
                                  'Expiry:',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  widget.product.expiryDate!,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),

            // Similar Products Section
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'More Products',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSimilarProducts(),
                  ],
                ),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),

        // Bottom Action Bar
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Delivery Information - Only show if active
                Consumer<MartProvider>(
                  builder: (context, martController, _) {
                    if (!martController.isDeliverySettingsActive) {
                      return const SizedBox.shrink(); // Hide if not active
                    }

                    return Row(
                      children: [
                        const Icon(Icons.lock, color: Colors.amber, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          martController.deliveryMessage,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            martController.deliveryPromotionText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                // Cart Action Buttons
                isInCart ? _buildCartActions() : _buildAddToCartButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Add a selected option (variant) to cart
  Future<void> _addOptionToCart(Map<String, dynamic> selectedOption) async {
    try {
      final martController = Provider.of<MartProvider>(context, listen: false);
      CartControllerProvider cartControllerProvider =
          Provider.of<CartControllerProvider>(context, listen: false);
      final cartProduct = CartProductModel(
        id: "${widget.product.id}_${selectedOption['id']}",
        name:
            "${widget.product.name} - ${selectedOption['option_title'] ?? selectedOption['option_subtitle'] ?? 'Option'}",
        photo: selectedOption['image']?.toString().isNotEmpty == true
            ? selectedOption['image'].toString()
            : widget.product.photo,
        price: selectedOption['original_price']?.toString() ??
            selectedOption['price']?.toString() ??
            widget.product.price.toString(),
        discountPrice: selectedOption['price']?.toString() ??
            widget.product.disPrice?.toString() ??
            widget.product.price.toString(),
        vendorID: "mart_${widget.product.vendorID ?? martController.selectedVendorId ?? 'unknown'}",
        vendorName: "Jippy Mart",
        categoryId: widget.product.categoryID,
        quantity: 1,
        extrasPrice: '0',
        extras: [],
        variantInfo: null,
        promoId: null,
      );
      final success = await cartControllerProvider.addToCart(
        cartProductModel: cartProduct,
        isIncrement: true,
        quantity: 1,
      );
      if (success) {
        await Future.delayed(const Duration(milliseconds: 300));
        _refreshCartStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${cartProduct.name} added to cart'),
              backgroundColor: Colors.green.shade600,
              duration: const Duration(seconds: 2),
              action: SnackBarAction(
                label: 'View Cart',
                textColor: Colors.white,
                onPressed: () {
                  Get.to(
                    () => const CartScreen(
                      hideBackButton: false,
                      source: 'mart',
                      isFromMartNavigation: false,
                    ),
                    fullscreenDialog: true,
                  );
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error adding option to cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to cart: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Show bottom sheet to choose an option (when product has options)
  void _showOptionsBottomSheet() {
    if (widget.product.options == null || widget.product.options!.isEmpty) return;
    final sheetHeight = MediaQuery.of(context).size.height * 0.6;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: sheetHeight,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.product.name ?? 'Choose option',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: widget.product.options!.length,
                itemBuilder: (context, index) {
                  final option = widget.product.options![index];
                  final hasDiscount = option['original_price'] != null &&
                      option['price'] != null &&
                      option['original_price'] > option['price'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: (option['image']?.toString().isNotEmpty == true)
                                ? NetworkImageWidget(
                                    imageUrl: option['image'].toString(),
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  )
                                : NetworkImageWidget(
                                    imageUrl: widget.product.photo,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option['option_title']?.toString() ??
                                    option['option_subtitle']?.toString() ??
                                    'Option',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '₹${option['price']?.toString() ?? '0'}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  if (hasDiscount) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '₹${option['original_price']?.toString() ?? '0'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: ColorConst.orangeLight,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              Navigator.pop(context);
                              _addOptionToCart(option);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Text(
                                'ADD',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildAddToCartButton() {
    final hasOptions = widget.product.has_options == true &&
        widget.product.options != null &&
        widget.product.options!.isNotEmpty;

    if (hasOptions) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _showOptionsBottomSheet,
          icon: const Icon(Icons.checklist_rounded, size: 22),
          label: const Text('Choose option'),
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorConst.orangeLight,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          try {
            final martController = Provider.of<MartProvider>(context, listen: false);
            CartControllerProvider cartControllerProvider =
                Provider.of<CartControllerProvider>(context, listen: false);
            final martVendorID = "mart_${widget.product.vendorID ?? martController.selectedVendorId ?? 'unknown'}";
            final cartProduct = CartProductModel(
              id: widget.product.id,
              name: widget.product.name,
              photo: widget.product.photo,
              price: widget.product.price?.toString() ?? '0',
              discountPrice:
                  widget.product.disPrice?.toString() ??
                  widget.product.price?.toString() ??
                  '0',
              vendorID: martVendorID,
              // Prefix with "mart_" to identify as mart item
              vendorName: "Jippy Mart",
              // Add vendor name to satisfy NOT NULL constraint
              categoryId: widget.product.categoryID,
              quantity: quantity,
              extrasPrice: '0',
              extras: [],
              variantInfo: null,
              promoId: null,
            );
            final success = await cartControllerProvider.addToCart(
              cartProductModel: cartProduct,
              isIncrement: true,
              quantity: quantity,
            );
            // Only show success message if item was actually added
            if (success) {
              // Wait a bit for the cart to update
              await Future.delayed(Duration(milliseconds: 500));
              // Refresh cart status to update UI
              _refreshCartStatus();
            }
          } catch (e) {
            print('Error adding to cart: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to add to cart: ${e.toString()}'),
                backgroundColor: Colors.red.shade600,
                duration: Duration(seconds: 3),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConst.orangeLight,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Add to cart',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCartActions() {
    // Get total cart items count from the global cart list
    final totalCartItems = HomeProvider.cartItem.fold(
      0,
      (sum, item) => sum + (item.quantity ?? 0),
    );

    return Row(
      children: [
        // View Cart Button
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to cart screen
                Get.to(
                  () => const CartScreen(
                    hideBackButton: false,
                    source: 'mart',
                    isFromMartNavigation: false,
                  ),
                  fullscreenDialog: true,
                );
              },
              icon: Stack(
                children: [
                  SvgPicture.asset(
                    'assets/icons/ic_shoping_cart.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      Colors.grey,
                      BlendMode.srcIn,
                    ),
                  ),
                  if (totalCartItems > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE91E63),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$totalCartItems',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: const Text(
                'View Cart',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.grey,
                elevation: 0,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                splashFactory: NoSplash.splashFactory,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Quantity Selector
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE91E63),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () async {
                    try {
                      final martController = Provider.of<MartProvider>(context, listen: false);
                      // Get the cart controller
                      CartControllerProvider cartControllerProvider =
                          Provider.of<CartControllerProvider>(
                            context,
                            listen: false,
                          );

                      // Create CartProductModel for removal
                      final martVendorID =
                          "mart_${widget.product.vendorID ?? martController.selectedVendorId ?? 'unknown'}";
                      final cartProduct = CartProductModel(
                        id: widget.product.id,
                        name: widget.product.name,
                        photo: widget.product.photo,
                        price: widget.product.price?.toString() ?? '0',
                        discountPrice:
                            widget.product.disPrice?.toString() ??
                            widget.product.price?.toString() ??
                            '0',
                        vendorID: martVendorID,
                        vendorName: "Jippy Mart",
                        categoryId: widget.product.categoryID,
                        quantity: cartQuantity,
                        extrasPrice: '0',
                        extras: [],
                        variantInfo: null,
                        promoId: null,
                      );

                      if (cartQuantity > 1) {
                        // Decrement quantity
                        cartControllerProvider.addToCart(
                          cartProductModel: cartProduct,
                          isIncrement: false,
                          quantity: cartQuantity - 1,
                        );
                      } else {
                        // Remove completely
                        cartControllerProvider.addToCart(
                          cartProductModel: cartProduct,
                          isIncrement: false,
                          quantity: 0,
                        );
                      }

                      // Wait a bit for the cart to update
                      await Future.delayed(Duration(milliseconds: 300));

                      // Refresh cart status to update UI
                      _refreshCartStatus();
                    } catch (e) {
                      print('Error removing from cart: $e');
                    }
                  },
                  icon: const Icon(Icons.remove, color: Colors.white),
                ),
                Text(
                  '$cartQuantity',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    try {
                      // Get the cart controller
                      CartControllerProvider cartControllerProvider =
                          Provider.of<CartControllerProvider>(
                            context,
                            listen: false,
                          );

                      // Create CartProductModel for addition
                      final martVendorID =
                          "mart_${widget.product.vendorID ?? 'unknown'}";
                      final cartProduct = CartProductModel(
                        id: widget.product.id,
                        name: widget.product.name,
                        photo: widget.product.photo,
                        price: widget.product.price?.toString() ?? '0',
                        discountPrice:
                            widget.product.disPrice?.toString() ??
                            widget.product.price?.toString() ??
                            '0',
                        vendorID: martVendorID,
                        vendorName: "Jippy Mart",
                        categoryId: widget.product.categoryID,
                        quantity: cartQuantity + 1,
                        extrasPrice: '0',
                        extras: [],
                        variantInfo: null,
                        promoId: null,
                      );

                      // Add one more item
                      cartControllerProvider.addToCart(
                        cartProductModel: cartProduct,
                        isIncrement: true,
                        quantity: cartQuantity + 1,
                      );

                      // Wait a bit for the cart to update
                      await Future.delayed(Duration(milliseconds: 300));

                      // Refresh cart status to update UI
                      _refreshCartStatus();
                    } catch (e) {
                      print('Error adding to cart: $e');
                    }
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<String> _getProductImages() {
    List<String> images = [];

    // Add main product image
    if (widget.product.photo != null && widget.product.photo!.isNotEmpty) {
      images.add(widget.product.photo!);
    }

    // Add additional images if available
    if (widget.product.photos != null && widget.product.photos!.isNotEmpty) {
      images.addAll(widget.product.photos!);
    }

    // If no images, add placeholder
    if (images.isEmpty) {
      images.add('https://via.placeholder.com/400x400');
    }

    return images;
  }

  Widget _buildSimilarProducts() {
    // Debug logging
    print('[SIMILAR PRODUCTS] Current product: ${widget.product.name}');
    print(
      '[SIMILAR PRODUCTS] Current product categoryID: ${widget.product.categoryID}',
    );
    print(
      '[SIMILAR PRODUCTS] Current product subcategoryID: ${widget.product.subcategoryID}',
    );
    // Check if we have the required categoryID
    if (widget.product.categoryID == null ||
        widget.product.categoryID!.isEmpty) {
      print(
        '[SIMILAR PRODUCTS] No categoryID available, cannot load similar products',
      );
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Center(
          child: Text(
            'No similar products available',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }
    // Initialize stream if not already initialized
    if (_similarProductsStream == null) {
      _initializeSimilarProductsStream();
    }
    // Use cached stream for real-time similar products loading
    return StreamBuilder<List<MartItemModel>>(
      stream: _similarProductsStream,
      builder: (context, snapshot) {
        print(
          '[SIMILAR PRODUCTS] Stream snapshot state: ${snapshot.connectionState}',
        );
        print('[SIMILAR PRODUCTS] Stream has data: ${snapshot.hasData}');
        print('[SIMILAR PRODUCTS] Stream has error: ${snapshot.hasError}');
        if (snapshot.hasData) {
          print(
            '[SIMILAR PRODUCTS] Stream data length: ${snapshot.data?.length ?? 0}',
          );
          print(
            '[SIMILAR PRODUCTS] Stream data: ${snapshot.data?.map((item) => item.name).toList()}',
          );
        }

        if (snapshot.hasError) {
          print('[SIMILAR PRODUCTS] Stream error: ${snapshot.error}');
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red[400], size: 32),
                const SizedBox(height: 8),
                const Text(
                  'Unable to load similar products',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Please check your connection',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          );
        }

        // Check if we have data first, regardless of connection state
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final similarProducts = snapshot.data!;
          print(
            '[SIMILAR PRODUCTS] Stream returned ${similarProducts.length} similar products',
          );

          return SizedBox(
            height: 280, // Increased height to accommodate 2-line titles
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: similarProducts.length,
              itemBuilder: (context, index) {
                final product = similarProducts[index];
                return Container(
                  width: 140, // Reduced width for more compact cards
                  margin: const EdgeInsets.only(right: 12),
                  child: _buildSimilarProductCard(product),
                );
              },
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          print('[SIMILAR PRODUCTS] Stream is waiting for data...');

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.purple[400]!,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Loading similar products...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Loading products from mart_items collection',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          print('[SIMILAR PRODUCTS] No similar products found in stream');
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.grey[400],
                  size: 32,
                ),
                const SizedBox(height: 8),
                const Text(
                  'No products found',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Try refreshing or check back later',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          );
        }

        // Fallback case - should never reach here, but required for null safety
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: const Center(
            child: Text(
              'Loading...',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSimilarProductCard(dynamic product) {
    return GestureDetector(
      onTap: () {
        // Navigate to product details screen
        Get.to(() => MartProductDetailsScreen(product: product));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: SizedBox(
                height: 150, // Increased image height to match new card height
                width: double.infinity,
                child: product.photo != null && product.photo!.isNotEmpty
                    ? NetworkImageWidget(
                        imageUrl: product.photo!,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          color: Colors.grey[100],
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/icons/ic_picture_one.svg',
                              width: 40,
                              height: 40,
                              colorFilter: ColorFilter.mode(
                                Colors.grey[400]!,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[100],
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/icons/ic_picture_one.svg',
                            width: 40,
                            height: 40,
                            colorFilter: ColorFilter.mode(
                              Colors.grey[400]!,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
              ),
            ),

            // Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10), // Slightly increased padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      product.name ?? 'Product Name',
                      style: const TextStyle(
                        fontSize: 13, // Slightly increased font size
                        fontWeight: FontWeight.w600,
                        height: 1.2, // Line height for better 2-line display
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6), // Slightly increased spacing
                    // Price
                    Row(
                      children: [
                        Text(
                          '₹${product.disPrice ?? product.price}',
                          style: const TextStyle(
                            fontSize: 14, // Reduced font size
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        if (product.disPrice != null &&
                            product.disPrice! < product.price) ...[
                          const SizedBox(width: 8),
                          Text(
                            '₹${product.price}',
                            style: TextStyle(
                              fontSize: 10, // Reduced font size
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Colors.red,
                              color: Colors.red[600],
                            ),
                          ),
                        ],
                      ],
                    ),

                    const Spacer(),

                    // Add to Cart Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            // Get the cart controller
                            CartControllerProvider cartControllerProvider =
                                Provider.of<CartControllerProvider>(
                                  context,
                                  listen: false,
                                );

                            // Convert MartItemModel to CartProductModel
                            final martVendorID =
                                "mart_${product.vendorID ?? 'unknown'}";
                            final cartProduct = CartProductModel(
                              id: product.id,
                              name: product.name,
                              photo: product.photo,
                              price: product.price?.toString() ?? '0',
                              discountPrice:
                                  product.disPrice?.toString() ??
                                  product.price?.toString() ??
                                  '0',
                              vendorID: martVendorID,
                              vendorName: "Jippy Mart",
                              categoryId: product.categoryID,
                              quantity: 1,
                              extrasPrice: '0',
                              extras: [],
                              variantInfo: null,
                              promoId: null,
                            );

                            // Add to cart
                            cartControllerProvider.addToCart(
                              cartProductModel: cartProduct,
                              isIncrement: true,
                              quantity: 1,
                            );

                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.name} added to cart'),
                                backgroundColor: Colors.green.shade600,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          } catch (e) {
                            print('Error adding to cart: $e');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConst.orangeLight,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                          ), // Smaller padding
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              3,
                            ), // Smaller border radius
                          ),
                        ),
                        child: const Text(
                          'ADD',
                          style: TextStyle(
                            fontSize: 12, // Smaller font size
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
