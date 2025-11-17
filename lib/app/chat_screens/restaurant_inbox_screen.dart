import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
import 'package:jippymart_customer/app/chat_screens/chat_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/inbox_model.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Add this import

class RestaurantInboxScreen extends StatefulWidget {
  const RestaurantInboxScreen({super.key, required this.userId});

  final String? userId;

  @override
  State<RestaurantInboxScreen> createState() => _RestaurantInboxScreenState();
}

class _RestaurantInboxScreenState extends State<RestaurantInboxScreen> {
  final RefreshController _refreshController = RefreshController();
  final List<InboxModel> _inboxList = [];
  int _currentPage = 1;
  bool _isLoading = true;
  bool _hasMore = true;

  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse(
      '${AppConst.baseUrl}$endpoint',
    ).replace(queryParameters: queryParams);
    return await http.get(uri, headers: await getHeaders());
  }

  @override
  void initState() {
    super.initState();
    _loadInboxData();
  }

  Future<void> _loadInboxData({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        _currentPage = 1;
        _hasMore = true;
        _inboxList.clear();
      }

      if (!_hasMore && !isRefresh) return;

      final response = await get(
        'chat/inbox',
        queryParams: {
          'chat_type': 'restaurant',
          'user_id': widget.userId.toString(),
          'page': _currentPage.toString(),
          'per_page': '20',
        },
      );

      if (response.statusCode == 200) {
        // Parse the JSON response
        final Map<String, dynamic> responseData = json.decode(response.body);
        final Map<String, dynamic> data = responseData['data'];
        final List<dynamic> inboxData = data['data'];

        setState(() {
          if (isRefresh) {
            _inboxList.clear();
          }

          _inboxList.addAll(
            inboxData.map((json) => InboxModel.fromJson(json)).toList(),
          );

          _currentPage = data['current_page'] + 1;
          _hasMore = data['current_page'] < data['last_page'];
          _isLoading = false;
        });

        if (isRefresh) {
          _refreshController.refreshCompleted();
        } else {
          _refreshController.loadComplete();
        }
      } else {
        _handleError(isRefresh);
      }
    } catch (e) {
      _handleError(isRefresh);
      ShowToastDialog.showToast("Failed to load messages".tr);
    }
  }

  void _handleError(bool isRefresh) {
    if (isRefresh) {
      _refreshController.refreshFailed();
    } else {
      _refreshController.loadFailed();
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _onRefresh() async {
    await _loadInboxData(isRefresh: true);
  }

  Future<void> _onLoading() async {
    if (_hasMore) {
      await _loadInboxData();
    } else {
      _refreshController.loadNoData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AddressListProvider>(
      builder: (context, addressListProvider, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppThemeData.surface,
            centerTitle: false,
            titleSpacing: 0,
            title: Text(
              "Restaurant Inbox".tr,
              textAlign: TextAlign.start,
              style: TextStyle(
                fontFamily: AppThemeData.medium,
                fontSize: 16,
                color: AppThemeData.grey900,
              ),
            ),
          ),
          body: _isLoading && _inboxList.isEmpty
              ? Constant.loader()
              : _inboxList.isEmpty
              ? Constant.showEmptyView(message: "No Conversion found".tr)
              : SmartRefresher(
                  controller: _refreshController,
                  enablePullUp: _hasMore,
                  onRefresh: _onRefresh,
                  onLoading: _onLoading,
                  physics: const BouncingScrollPhysics(),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _inboxList.length,
                    itemBuilder: (context, index) {
                      final inboxModel = _inboxList[index];
                      return _buildInboxItem(inboxModel);
                    },
                  ),
                ),
        );
      },
    );
  }

  Widget _buildInboxItem(InboxModel inboxModel) {
    return InkWell(
      onTap: () async {
        await _openChatScreen(inboxModel);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Container(
          decoration: ShapeDecoration(
            color: AppThemeData.grey50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  child: NetworkImageWidget(
                    imageUrl: inboxModel.restaurantProfileImage.toString(),
                    fit: BoxFit.cover,
                    height: Responsive.height(6, context),
                    width: Responsive.width(12, context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              inboxModel.restaurantName ?? "Restaurant",
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                fontFamily: AppThemeData.semiBold,
                                fontSize: 16,
                                color: AppThemeData.grey800,
                              ),
                            ),
                          ),
                          Text(
                            Constant.timestampToDate(inboxModel.createdAt!),
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontFamily: AppThemeData.regular,
                              fontSize: 16,
                              color: AppThemeData.grey500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        inboxModel.lastMessage ?? "",
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontFamily: AppThemeData.medium,
                          fontSize: 14,
                          color: AppThemeData.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openChatScreen(InboxModel inboxModel) async {
    ShowToastDialog.showLoader("Please wait".tr);
    try {
      UserModel? customer = await AddressListProvider.getUserProfile(
        inboxModel.customerId.toString(),
      );
      UserModel? restaurantUser = await AddressListProvider.getUserProfile(
        inboxModel.restaurantId.toString(),
      );
      VendorModel? vendorModel = await FireStoreUtils.getVendorById(
        restaurantUser!.vendorID.toString(),
      );
      ShowToastDialog.closeLoader();

      final userId = await SqlStorageConst.getFirebaseId();
      Get.to(
        ChatScreen(userId: userId),
        arguments: {
          "customerName": customer!.fullName(),
          "restaurantName": vendorModel!.title,
          "orderId": inboxModel.orderId,
          "restaurantId": restaurantUser.id,
          "customerId": customer.id,
          "customerProfileImage": customer.profilePictureURL,
          "restaurantProfileImage": vendorModel.photo,
          "token": restaurantUser.fcmToken,
          "chatType": inboxModel.chatType,
        },
      );
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Failed to open chat".tr);
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }
}
