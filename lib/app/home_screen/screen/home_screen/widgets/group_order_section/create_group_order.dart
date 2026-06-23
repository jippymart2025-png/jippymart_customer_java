import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/app/home_screen/screen/home_screen/provider/best_restaurants_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/widget/restaurant_image_with_status.dart';

import 'InviteFriendsScreen.dart';
import 'create_group_orders_model.dart';

enum GroupPaymentMode { splitIndividually, hostPays }

class CreateGroupOrderScreen extends StatefulWidget {
  const CreateGroupOrderScreen({super.key});

  @override
  State<CreateGroupOrderScreen> createState() => _CreateGroupOrderScreenState();
}

class _CreateGroupOrderScreenState extends State<CreateGroupOrderScreen> {
  String _closingTime = '30 mins';
  String _maxMembers = '10 members';
  GroupPaymentMode _paymentMode = GroupPaymentMode.splitIndividually;

  List<VendorModel> _restaurants = [];
  VendorModel? _selectedVendor;
  bool _isLoadingRestaurants = true;
  String? _restaurantLoadError;

  final List<String> _closingTimeOptions = [
    '15 mins',
    '30 mins',
    '45 mins',
    '60 mins',
  ];
  final List<String> _maxMembersOptions = [
    '5 members',
    '10 members',
    '15 members',
    '20 members',
  ];

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    setState(() {
      _isLoadingRestaurants = true;
      _restaurantLoadError = null;
    });

    try {
      final cached = Constant.restaurantList ?? <VendorModel>[];
      if (cached.isNotEmpty) {
        setState(() {
          _restaurants = List<VendorModel>.from(cached);
          _isLoadingRestaurants = false;
        });
        return;
      }

      final latitude = Constant.selectedLocation.location?.latitude ?? 0.0;
      final longitude = Constant.selectedLocation.location?.longitude ?? 0.0;

      if (latitude == 0.0 || longitude == 0.0) {
        setState(() {
          _restaurants = [];
          _isLoadingRestaurants = false;
          _restaurantLoadError = 'Please set your delivery location first.';
        });
        return;
      }

      final restaurants = await BestRestaurantProvider.getNearestRestaurants(
        latitude: latitude,
        longitude: longitude,
      );

      if (!mounted) return;

      setState(() {
        _restaurants = restaurants;
        _isLoadingRestaurants = false;
        if (restaurants.isEmpty) {
          _restaurantLoadError = 'No restaurants found near your location.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _restaurants = [];
        _isLoadingRestaurants = false;
        _restaurantLoadError = 'Failed to load restaurants. Please try again.';
      });
    }
  }

  void _selectRestaurant(VendorModel vendor) {
    setState(() => _selectedVendor = vendor);
  }

  SelectedRestaurant? get _selectedRestaurant => _selectedVendor == null
      ? null
      : SelectedRestaurant.fromVendorModel(_selectedVendor!);

  void _showRestaurantPicker() {
    if (_restaurants.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppThemeData.grey200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Choose Restaurant',
                        style: TextStyle(
                          fontFamily: AppThemeData.semiBold,
                          color: AppThemeData.grey900,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppThemeData.grey500,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _restaurants.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final vendor = _restaurants[index];
                    return _buildRestaurantTile(
                      vendor,
                      onSelected: () {
                        _selectRestaurant(vendor);
                        Navigator.pop(sheetContext);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppThemeData.grey900,
            size: 18,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Create Group Order',
          style: TextStyle(
            fontFamily: AppThemeData.extraBold,
            color: AppThemeData.grey900,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionLabel('Choose Restaurant'),
          const SizedBox(height: 8),
          _buildRestaurantDropdown(),
          const SizedBox(height: 22),
          _sectionLabel('Order settings'),
          const SizedBox(height: 10),
          _buildDropdownRow(
            label: 'Order closing time',
            value: _closingTime,
            options: _closingTimeOptions,
            onChanged: (v) => setState(() => _closingTime = v),
          ),
          const SizedBox(height: 12),
          _buildDropdownRow(
            label: 'Maximum members',
            value: _maxMembers,
            options: _maxMembersOptions,
            onChanged: (v) => setState(() => _maxMembers = v),
          ),
          const SizedBox(height: 22),
          _sectionLabel('Payment mode'),
          const SizedBox(height: 10),
          _buildPaymentOption(
            mode: GroupPaymentMode.splitIndividually,
            title: 'Split Individually',
          ),
          const SizedBox(height: 10),
          _buildPaymentOption(
            mode: GroupPaymentMode.hostPays,
            title: 'Host Pays',
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B2C),
                disabledBackgroundColor: const Color(0xFFFFCBA8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: _selectedRestaurant == null
                  ? null
                  : () {
                      // TODO: actually create the group order on your backend here,
                      // then pass the real group code / link it returns.
                      Get.to(
                        () => InviteFriendsScreen(
                          groupCode: 'FD9842',
                          groupLink: 'https://foodie.in/g/FD9842',
                        ),
                      );
                    },
              child: const Text(
                'Create Group',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppThemeData.semiBold,
        color: AppThemeData.grey900,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildRestaurantDropdown() {
    if (_isLoadingRestaurants) {
      return Container(
        height: 68,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppThemeData.grey100),
        ),
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: Color(0xFFFF6B2C),
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (_restaurantLoadError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppThemeData.grey100),
        ),
        child: Column(
          children: [
            Text(
              _restaurantLoadError!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppThemeData.medium,
                color: AppThemeData.grey600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadRestaurants,
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Color(0xFFFF6B2C),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final selected = _selectedRestaurant;

    return InkWell(
      onTap: _showRestaurantPicker,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppThemeData.grey100),
        ),
        child: Row(
          children: [
            if (selected != null && _selectedVendor != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: RestaurantImageWithStatus(
                  vendorModel: _selectedVendor!,
                  width: 44,
                  height: 44,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selected.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppThemeData.semiBold,
                        color: AppThemeData.grey900,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${selected.rating} • ${selected.etaLabel}',
                      style: TextStyle(
                        fontFamily: AppThemeData.medium,
                        color: AppThemeData.grey500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Expanded(
                child: Text(
                  'Select a restaurant',
                  style: TextStyle(
                    fontFamily: AppThemeData.medium,
                    color: AppThemeData.grey500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppThemeData.grey600,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantTile(
    VendorModel vendor, {
    required VoidCallback onSelected,
  }) {
    final selected = _selectedVendor?.id == vendor.id;
    final restaurant = SelectedRestaurant.fromVendorModel(vendor);

    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF1E6) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFFF6B2C) : AppThemeData.grey100,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: RestaurantImageWithStatus(
                vendorModel: vendor,
                width: 52,
                height: 52,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppThemeData.semiBold,
                      color: AppThemeData.grey900,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${restaurant.rating} • ${restaurant.etaLabel}',
                    style: TextStyle(
                      fontFamily: AppThemeData.medium,
                      color: AppThemeData.grey500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? const Color(0xFFFF6B2C) : AppThemeData.grey400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownRow({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppThemeData.medium,
            color: AppThemeData.grey800,
            fontSize: 14,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppThemeData.grey100),
          ),
          child: DropdownButton<String>(
            value: value,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
            style: TextStyle(
              fontFamily: AppThemeData.semiBold,
              color: AppThemeData.grey900,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
            items: options
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required GroupPaymentMode mode,
    required String title,
  }) {
    final bool selected = _paymentMode == mode;
    return InkWell(
      onTap: () => setState(() => _paymentMode = mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF1E6) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFFF6B2C) : AppThemeData.grey100,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? const Color(0xFFFF6B2C) : AppThemeData.grey500,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontFamily: AppThemeData.semiBold,
                color: AppThemeData.grey900,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (mode == GroupPaymentMode.hostPays)
              Icon(Icons.chevron_right_rounded, color: AppThemeData.grey500),
          ],
        ),
      ),
    );
  }
}
