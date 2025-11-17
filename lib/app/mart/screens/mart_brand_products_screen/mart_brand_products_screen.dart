import 'dart:convert';

import 'package:jippymart_customer/app/cart_screen/provider/cart_provider.dart';
import 'package:jippymart_customer/app/mart/mart_home_screen/provider/mart_provider.dart';
import 'package:jippymart_customer/app/mart/widgets/mart_product_card.dart';
import 'package:jippymart_customer/models/mart_brand_model.dart';
import 'package:jippymart_customer/models/mart_item_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class MartBrandProductsScreen extends StatefulWidget {
  final String brandID;
  final String brandTitle;

  const MartBrandProductsScreen({
    super.key,
    required this.brandID,
    required this.brandTitle,
  });

  @override
  State<MartBrandProductsScreen> createState() =>
      _MartBrandProductsScreenState();
}

class _MartBrandProductsScreenState extends State<MartBrandProductsScreen> {
  late MartProvider _martController;

  late CartControllerProvider cartControllerProvider;

  MartBrandModel? brandData;

  @override
  void initState() {
    cartControllerProvider = Provider.of<CartControllerProvider>(
      context,
      listen: false,
    );
    _martController = Provider.of<MartProvider>(context, listen: false);

    super.initState();
    _fetchBrandData();
  }

  Future<void> _fetchBrandData() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConst.baseUrl}mobile/brands/${widget.brandID}'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          setState(() {
            brandData = MartBrandModel.fromJson(jsonResponse['data']['brand']);
          });
        }
      } else {
        print('Error fetching brand data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching brand data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppThemeData.homeScreenBackground, // Reusable home screen background
      appBar: AppBar(
        backgroundColor: const Color(0xFF20B2AA),
        // Teal color like search section
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Get.back(),
          ),
        ),
        title: Row(
          children: [
            // Brand Logo in App Bar
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 8),
              child: brandData?.logoUrl != null && brandData!.logoUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: NetworkImageWidget(
                        imageUrl: brandData!.logoUrl,
                        fit: BoxFit.contain,
                        errorWidget: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.business,
                            color: Colors.black87,
                            size: 16,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.business,
                        color: Colors.black87,
                        size: 16,
                      ),
                    ),
            ),
            // Brand Name
            Text(
              widget.brandTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<List<MartItemModel>>(
        stream: _martController.streamProductsByBrand(widget.brandID),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5D56F3)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading products',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check your connection and try again',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D56F3),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No products found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No products available for ${widget.brandTitle} brand',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final products = snapshot.data!;

          return Column(
            children: [
              // Products Grid
              Expanded(
                child: Align(
                  alignment: Alignment
                      .topLeft, // 🔑 Ensure content starts from top-left
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          Colors.transparent, // Remove white background layer
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = constraints.maxWidth;
                        final isTablet = screenWidth > 600;
                        final isLargePhone = screenWidth > 400;

                        // Calculate dynamic values based on screen size
                        final crossAxisCount = isTablet ? 3 : 2;
                        final spacing = isTablet
                            ? 12.0
                            : (isLargePhone ? 8.0 : 4.0);
                        final horizontalPadding = isTablet
                            ? 16.0
                            : (isLargePhone ? 8.0 : 4.0);

                        // 🔑 Auto-adjustable layout using Wrap for truly flexible card heights
                        return SingleChildScrollView(
                          padding: EdgeInsets.only(
                            left: horizontalPadding,
                            right: horizontalPadding,
                            bottom: MediaQuery.of(context).padding.bottom + 8,
                            top: 4,
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.start,
                            // 🔑 Ensure products start from the left
                            crossAxisAlignment: WrapCrossAlignment.start,
                            // 🔑 Ensure products start from the top
                            runAlignment: WrapAlignment.start,
                            // 🔑 Ensure runs start from the top
                            spacing: spacing,
                            runSpacing: spacing,
                            children: products.map((product) {
                              // Calculate card width based on screen size and crossAxisCount
                              final cardWidth =
                                  (screenWidth -
                                      horizontalPadding * 2 -
                                      spacing * (crossAxisCount - 1)) /
                                  crossAxisCount;

                              // Using MartProductCard with calculated width for proper sizing
                              return SizedBox(
                                width: cardWidth,
                                child: MartProductCard(
                                  product: product,
                                  screenWidth: screenWidth,
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
