import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/app/home_screen/screen/group_order_section/service/group_order_api_service.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import '../model/create_group_orders_model.dart';
import '../service/restaurant_service.dart';
import '../widgets/buildRestaurantTile.dart';
import '../widgets/dropdown_setting_tile.dart';
import '../widgets/payment_option_tile.dart';
import '../widgets/restaurant_dropdown.dart';
import 'InviteFriendsScreen.dart';

enum GroupPaymentMode { splitIndividually, hostPays }

class CreateGroupOrderScreen extends StatefulWidget {
  const CreateGroupOrderScreen({super.key});

  @override
  State<CreateGroupOrderScreen> createState() => _CreateGroupOrderScreenState();
}

class _CreateGroupOrderScreenState extends State<CreateGroupOrderScreen> {
  final RestaurantService _restaurantService = RestaurantService();

  int _closingMinutes = 30;
  int _maxMembers = 10;
  GroupPaymentMode _paymentMode = GroupPaymentMode.splitIndividually;

  List<VendorModel> _restaurants = [];
  VendorModel? _selectedVendor;
  bool _isLoadingRestaurants = true;
  bool _isCreatingGroup = false;
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
      final restaurants = await _restaurantService.loadRestaurants();

      if (!mounted) return;

      setState(() {
        _restaurants = restaurants;

        _isLoadingRestaurants = false;

        _restaurantLoadError = restaurants.isEmpty
            ? "No restaurants found"
            : null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _restaurants = [];

        _isLoadingRestaurants = false;

        _restaurantLoadError = "Failed to load restaurants";
      });
    }
  }

  void _selectRestaurant(VendorModel vendor) {
    setState(() => _selectedVendor = vendor);
  }

  SelectedRestaurant? get _selectedRestaurant => _selectedVendor == null
      ? null
      : SelectedRestaurant.fromVendorModel(_selectedVendor!);

  int _parseMinutes(String value) => int.tryParse(value.split(' ').first) ?? 30;

  String _paymentResponsibility() {
    return _paymentMode == GroupPaymentMode.splitIndividually
        ? 'INDIVIDUAL'
        : 'HOST';
  }

  Future<void> _createGroupOrder() async {
    if (_selectedVendor == null || _isCreatingGroup) return;

    final customerId = int.tryParse(await SqlStorageConst.getUserId() ?? '');
    if (customerId == null) {
      ShowToastDialog.showToast('Please log in to create a group order');
      return;
    }

    final outletId = int.tryParse(_selectedVendor!.id ?? '');
    if (outletId == null) {
      ShowToastDialog.showToast('Invalid restaurant selected');
      return;
    }

    setState(() => _isCreatingGroup = true);
    ShowToastDialog.showLoader('Creating group...');

    try {
      final result = await GroupOrderApiService.createGroupOrderInvitation(
        hostCustomerId: customerId,
        outletId: outletId,
        orderCloseDurationInMinutes: _parseMinutes("$_closingMinutes mins"),
        paymentResponsibility: _paymentResponsibility(),
        maxMembers: _maxMembers,
        createdBy: customerId,
      );

      ShowToastDialog.closeLoader();
      if (!mounted) return;
      setState(() => _isCreatingGroup = false);

      if (result == null || result.invitationCode.isEmpty) {
        ShowToastDialog.showToast('Failed to create group order');
        return;
      }

      final invitationCode = result.invitationCode;
      Get.to(
        () => InviteFriendsScreen(
          groupCode: invitationCode,
          groupLink:
              'https://jippymart.in/g/${result.groupOrdersInvitationId}/$invitationCode/${result.hostCustomerId}',
          restaurant: _selectedVendor!,
          groupOrdersInvitationId: result.groupOrdersInvitationId,
          hostCustomerId: result.hostCustomerId,
        ),
      );
    } catch (e, stack) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stack);

      ShowToastDialog.showToast("Failed to create group");
    }
  }

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

                    return buildRestaurantTile(
                      vendor,
                      isSelected: _selectedVendor?.id == vendor.id,
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
      backgroundColor: AppThemeData.surface,
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
          RestaurantDropdown(
            isLoading: _isLoadingRestaurants,
            error: _restaurantLoadError,
            selectedVendor: _selectedVendor,
            selectedRestaurant: _selectedRestaurant,
            onTap: _showRestaurantPicker,
            onRetry: _loadRestaurants,
          ),
          const SizedBox(height: 22),

          _sectionLabel('Order settings'),
          const SizedBox(height: 10),
          DropdownSettingTile(
            label: 'Order closing time',
            value: "$_closingMinutes mins",
            options: _closingTimeOptions,
            onChanged: (v) {
              setState(() {
                _closingMinutes = _parseMinutes(v);
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownSettingTile(
            label: 'Maximum members',
            value: "$_maxMembers members",
            options: _maxMembersOptions,
            onChanged: (v) {
              setState(() {
                _maxMembers = int.parse(v.split(' ').first);
              });
            },
          ),
          const SizedBox(height: 22),
          _sectionLabel('Payment mode'),
          const SizedBox(height: 10),
          PaymentOptionTile(
            mode: GroupPaymentMode.splitIndividually,
            selectedMode: _paymentMode,
            title: 'Split Individually',
            onChanged: (mode) {
              setState(() {
                _paymentMode = mode;
              });
            },
          ),
          const SizedBox(height: 10),
          PaymentOptionTile(
            mode: GroupPaymentMode.hostPays,
            selectedMode: _paymentMode,
            title: 'Host Pays',
            onChanged: (mode) {
              setState(() {
                _paymentMode = mode;
              });
            },
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
                backgroundColor: AppThemeData.primary1000,
                disabledBackgroundColor: AppThemeData.primary2000,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: _selectedRestaurant == null || _isCreatingGroup
                  ? null
                  : _createGroupOrder,
              child: _isCreatingGroup
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
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
}
