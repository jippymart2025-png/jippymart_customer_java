import 'dart:async';
import 'dart:convert';

import 'package:jippymart_customer/app/auth_screen/login_screen.dart';
import 'package:jippymart_customer/app/dash_board_screens/provider/dash_board_provider.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/live_tracking_screen/live_tracking_screen.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/live_tracking_screen/provider/live_tracking_provider.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/order_deatils_screen/order_details_screen.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/order_deatils_screen/provider/order_details_provider.dart';
import 'package:jippymart_customer/app/order_list_screen/screens/order_screen/provider/order_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/order_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/themes/round_button_fill.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/color_const.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:jippymart_customer/utils/utils/image_const.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:jippymart_customer/widget/my_separator.dart';
import 'package:jippymart_customer/widgets/app_loading_widget.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../../../../models/cart_product_model.dart';
import '../../../auth_screen/phone_number_screen.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  bool _isRefreshing = false;
  Timer? _debounceTimer;
  static const double _loadMoreTriggerOffset = 200;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - _loadMoreTriggerOffset) {
      final orderProvider = context.read<OrderProvider>();
      if (orderProvider.hasNextPage && !orderProvider.isLoadingMore) {
        orderProvider.loadMoreOrders();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Guard against building when widget is being disposed or removed from tree
    if (!mounted) {
      return const SizedBox.shrink();
    }

    return Consumer2<DashBoardProvider, OrderProvider>(
      builder: (context, dashBoardProvider, controller, _) {
        // Additional mounted check inside builder
        if (!mounted) {
          return const SizedBox.shrink();
        }

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(ImageConst.backgroundImage),
                fit: BoxFit.cover,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).viewPadding.top,
              ),
              child: _buildContent(context, controller),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, OrderProvider controller) {
    if (controller.isLoading && !_isRefreshing) {
      return const OrderLoadingWidget(message: "🍽️ Loading Your Orders");
    }

    if (Constant.userModel == null) {
      return _buildLoginPrompt();
    }

    return _buildOrderList(controller);
  }

  Widget _buildLoginPrompt() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset("assets/images/login.gif", height: 140),
          const SizedBox(height: 12),
          Text(
            "Please Log In to Continue".tr,
            style: TextStyle(
              color: AppThemeData.grey800,
              fontSize: 22,
              fontFamily: AppThemeData.semiBold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "You're not logged in. Please sign in to access your account and explore all features."
                .tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppThemeData.grey500,
              fontSize: 16,
              fontFamily: AppThemeData.bold,
            ),
          ),
          const SizedBox(height: 20),
          RoundedButtonFill(
            title: "Log in".tr,
            width: 55,
            height: 5.5,
            color: AppThemeData.primary300,
            textColor: AppThemeData.grey50,
            onPress: () {
              Get.offAll(() => PhoneNumberScreen());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(OrderProvider controller) {
    // Add key to ensure TabController is properly recreated when needed
    return DefaultTabController(
      key: const ValueKey('order_tab_controller'),
      length: 6,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "My Order".tr,
                        style: TextStyle(
                          fontSize: 24,
                          color: AppThemeData.grey900,
                          fontFamily: AppThemeData.semiBold,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: AppThemeData.primary300),
                  onPressed: () => _refreshOrders(controller),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildTabBar(),
                  const SizedBox(height: 10),
                  Expanded(child: _buildTabViews(controller)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: ShapeDecoration(
        color: AppThemeData.grey100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(120)),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: AppThemeData.primary300,
        ),
        labelColor: AppThemeData.grey50,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorWeight: 0.5,
        unselectedLabelColor: AppThemeData.grey900,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: [
          _buildTab('All'.tr),
          _buildTab('New Orders'.tr),
          _buildTab('In Progress'.tr),
          _buildTab('Delivered'.tr),
          _buildTab('Cancelled'.tr),
          _buildTab('Rejected'.tr),
        ],
      ),
    );
  }

  Widget _buildTab(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Tab(child: Text(text, style: const TextStyle(fontSize: 12))),
    );
  }

  Widget _buildTabViews(OrderProvider controller) {
    // Guard against building tab views when widget is not mounted
    if (!mounted) {
      return const SizedBox.shrink();
    }

    return TabBarView(
      key: const ValueKey('order_tab_view'),
      children: [
        _buildOrderListView(
          controller.allList,
          controller,
          'Order Not Found'.tr,
        ),
        _buildOrderListView(
          controller.newOrderList,
          controller,
          'Order Not Found'.tr,
        ),
        _buildOrderListView(
          controller.inProgressList,
          controller,
          'Order Not Found'.tr,
        ),
        _buildOrderListView(
          controller.deliveredList,
          controller,
          'Order Not Found'.tr,
        ),
        _buildOrderListView(
          controller.cancelledList,
          controller,
          'Order Not Found'.tr,
        ),
        _buildOrderListView(
          controller.rejectedList,
          controller,
          'Order Not Found'.tr,
        ),
      ],
    );
  }

  Widget _buildOrderListView(
    List<OrderModel> orderList,
    OrderProvider controller,
    String emptyMessage,
  ) {
    if (orderList.isEmpty && !controller.isLoading) {
      return Constant.showEmptyView(message: emptyMessage);
    }

    final hasMore = controller.hasNextPage;
    final itemCount = orderList.length + (hasMore ? 1 : 0);

    return RefreshIndicator(
      onRefresh: () => _refreshOrders(controller),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: itemCount,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        cacheExtent: 600,
        addAutomaticKeepAlives: true,
        addRepaintBoundaries: true,
        itemBuilder: (context, index) {
          if (index == orderList.length) {
            return _buildLoadMoreFooter(controller);
          }
          final order = orderList[index];
          return RepaintBoundary(
            key: ValueKey(order.id ?? index),
            child: _buildItemView(context, order, controller),
          );
        },
      ),
    );
  }

  Widget _buildLoadMoreFooter(OrderProvider controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: controller.isLoadingMore
            ? const SizedBox(
                height: 32,
                width: 32,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                'Scroll for more'.tr,
                style: TextStyle(
                  fontSize: 12,
                  color: AppThemeData.grey500,
                  fontFamily: AppThemeData.medium,
                ),
              ),
      ),
    );
  }

  Widget _buildItemView(
    BuildContext context,
    OrderModel orderModel,
    OrderProvider controller,
  ) {
    return GestureDetector(
      onTap: () {
        final orderDetailsProvider = context.read<OrderDetailsProvider>();
        _navigateToOrderDetails(orderModel, orderDetailsProvider);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Card(
          elevation: 4,
          color: ColorConst.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildOrderHeader(orderModel, context),
                const SizedBox(height: 10),
                _buildOrderTotal(orderModel),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: MySeparator(color: AppThemeData.grey200),
                ),
                _buildOrderActions(context, orderModel, controller),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHeader(OrderModel orderModel, BuildContext context) {
    return Row(
      children: [
        _buildVendorImage(orderModel, context),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  orderModel.status.toString(),
                  style: TextStyle(
                    color: Constant.statusColor(
                      status: orderModel.status.toString(),
                    ),
                    fontFamily: AppThemeData.semiBold,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                orderModel.vendor?.title?.toString() ?? "Jippy Mart",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  color: AppThemeData.grey900,
                  fontFamily: AppThemeData.medium,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                orderModel.createdAt != null
                    ? Constant.timestampToDateTime(orderModel.createdAt!)
                    : "Order placed",
                style: TextStyle(
                  color: AppThemeData.grey600,
                  fontFamily: AppThemeData.medium,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVendorImage(OrderModel orderModel, BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      child: SizedBox(
        height: Responsive.height(10, context),
        width: Responsive.width(20, context),
        child: Stack(
          children: [
            if (orderModel.vendor?.photo != null &&
                orderModel.vendor!.photo!.isNotEmpty)
              NetworkImageWidget(
                imageUrl: orderModel.vendor!.photo!,
                fit: BoxFit.cover,
                height: Responsive.height(10, context),
                width: Responsive.width(20, context),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: AppThemeData.grey200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.store,
                  color: AppThemeData.grey500,
                  size: Responsive.width(5, context),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(0.00, 1.00),
                  end: const Alignment(0, -1),
                  colors: [Colors.black.withOpacity(0), AppThemeData.grey900],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTotal(OrderModel orderModel) {
    final double toPayAmount = orderModel.toPayAmount ?? 0.0;

    return Row(
      children: [
        Expanded(
          child: Text(
            "Total to Pay",
            style: TextStyle(
              color: AppThemeData.grey900,
              fontFamily: AppThemeData.semiBold,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        Text(
          Constant.amountShow(amount: toPayAmount.toString()),
          style: TextStyle(
            color: AppThemeData.primary300,
            fontFamily: AppThemeData.semiBold,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderActions(
    BuildContext context,
    OrderModel orderModel,
    OrderProvider controller,
  ) {
    return Row(
      children: [
        if (orderModel.status == Constant.orderCompleted ||
            orderModel.status == Constant.pending)
          Expanded(
            child: InkWell(
              onTap: () => _reorderItems(context, orderModel, controller),
              child: Text(
                "Reorder".tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppThemeData.primary300,
                  fontFamily: AppThemeData.semiBold,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          )
        else if (orderModel.status == Constant.orderShipped ||
            orderModel.status == Constant.orderInTransit)
          Expanded(
            child: InkWell(
              onTap: () {
                context.read<LiveTrackingProvider>().initFunction(
                  orderModel: orderModel,
                );
                Get.to(const OrderDetailsScreen());
              },
              child: Text(
                "Track Order".tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppThemeData.primary300,
                  fontFamily: AppThemeData.semiBold,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          )
        else
          const SizedBox(),

        Expanded(
          child: InkWell(
            onTap: () {
              final orderDetailsProvider = context.read<OrderDetailsProvider>();
              _navigateToOrderDetails(orderModel, orderDetailsProvider);
            },
            child: Text(
              "View Details".tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppThemeData.grey900,
                fontFamily: AppThemeData.semiBold,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _reorderItems(
    BuildContext context,
    OrderModel orderModel,
    OrderProvider controller,
  ) async {
    await controller.reorderOrder(orderModel, context);
  }

  Future<void> _navigateToOrderDetails(
    OrderModel orderModel,
    OrderDetailsProvider orderDetailsProvider,
  ) async {
    if (_debounceTimer?.isActive ?? false) return;

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {});

    try {
      // Fetch surge fee in background
      final surgeFeeFuture = fetchOrderSergeFee(orderModel.id ?? '');

      orderDetailsProvider.initFunction(orderModels: orderModel);

      final surgeFee = await surgeFeeFuture;
      Get.to(() => OrderDetailsScreen(surgeFee: surgeFee));
    } catch (e) {
      ShowToastDialog.showToast("Error loading order details".tr);
    }
  }

  Future<void> _refreshOrders(OrderProvider controller) async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    try {
      await controller.refreshOrders();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<double?> fetchOrderSergeFee(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConst.baseUrl}mobile/orders/$orderId/billing/surge-fee',
        ),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final billingData = data['data'];
          return billingData['total_surge_fee']?.toDouble();
        }
      }

      return null;
    } catch (e) {
      print('Error fetching surge fee: $e');
      return null;
    }
  }
}
