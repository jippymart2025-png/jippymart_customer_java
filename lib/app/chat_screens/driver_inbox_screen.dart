import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jippymart_customer/app/address_screens/provider/address_list_provider.dart';
import 'package:jippymart_customer/app/chat_screens/chat_screen.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/inbox_model.dart';
import 'package:jippymart_customer/models/user_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/themes/responsive.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';

class DriverInboxScreen extends StatefulWidget {
  const DriverInboxScreen({super.key, required this.userId});

  final String userId;

  @override
  State<DriverInboxScreen> createState() => _DriverInboxScreenState();
}

class _DriverInboxScreenState extends State<DriverInboxScreen> {
  final List<InboxModel> _inboxList = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _perPage = 20;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInboxData();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        _hasMore &&
        !_isLoading) {
      _loadMoreData();
    }
  }

  Future<void> _loadInboxData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final Uri uri = Uri.parse('${AppConst.baseUrl}chat/inbox').replace(
        queryParameters: {
          'chat_type': 'driver',
          'user_id': widget.userId,
          'page': '1',
          'per_page': _perPage.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == true) {
          final data = responseData['data'];
          setState(() {
            _inboxList.clear();
            _inboxList.addAll(
              (data['data'] as List)
                  .map((item) => InboxModel.fromJson(item))
                  .toList(),
            );
            _currentPage = data['current_page'];
            _hasMore = data['next_page_url'] != null;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          ShowToastDialog.showToast('Failed to load inbox data');
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        ShowToastDialog.showToast(
          'Failed to load data: ${response.statusCode}',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ShowToastDialog.showToast('Error: $e');
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final Uri uri = Uri.parse('${AppConst.baseUrl}chat/inbox').replace(
        queryParameters: {
          'chat_type': 'driver',
          'user_id': widget.userId,
          'page': (_currentPage + 1).toString(),
          'per_page': _perPage.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['status'] == true) {
          final data = responseData['data'];
          final newItems = (data['data'] as List)
              .map((item) => InboxModel.fromJson(item))
              .toList();

          setState(() {
            _inboxList.addAll(newItems);
            _currentPage = data['current_page'];
            _hasMore = data['next_page_url'] != null;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          ShowToastDialog.showToast('Failed to load more data');
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        ShowToastDialog.showToast(
          'Failed to load more data: ${response.statusCode}',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ShowToastDialog.showToast('Error: $e');
    }
  }

  Future<void> _refreshData() async {
    _currentPage = 1;
    _hasMore = true;
    await _loadInboxData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppThemeData.surface,
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          "Driver Inbox".tr,
          textAlign: TextAlign.start,
          style: TextStyle(
            fontFamily: AppThemeData.medium,
            fontSize: 16,
            color: AppThemeData.grey900,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _isLoading && _inboxList.isEmpty
            ? Constant.loader()
            : _inboxList.isEmpty
            ? Constant.showEmptyView(message: "No Conversion found".tr)
            : ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                itemCount: _inboxList.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _inboxList.length) {
                    return _hasMore
                        ? const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : const SizedBox.shrink();
                  }

                  final inboxModel = _inboxList[index];
                  return InkWell(
                    onTap: () async {
                      ShowToastDialog.showLoader("Please wait".tr);

                      UserModel? customer =
                          await AddressListProvider.getUserProfile(
                            inboxModel.customerId.toString(),
                          );
                      UserModel? restaurantUser =
                          await AddressListProvider.getUserProfile(
                            inboxModel.restaurantId.toString(),
                          );
                      ShowToastDialog.closeLoader();

                      final userId = await SqlStorageConst.getFirebaseId();
                      Get.to(
                        ChatScreen(userId: userId),
                        arguments: {
                          "customerName": customer?.fullName(),
                          "restaurantName": restaurantUser!.fullName(),
                          "orderId": inboxModel.orderId,
                          "restaurantId": restaurantUser.id,
                          "customerId": customer?.id,
                          "customerProfileImage": customer?.profilePictureURL,
                          "restaurantProfileImage":
                              restaurantUser.profilePictureURL,
                          "token": restaurantUser.fcmToken,
                          "chatType": inboxModel.chatType,
                        },
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
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
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(10),
                                ),
                                child: NetworkImageWidget(
                                  imageUrl: inboxModel.restaurantProfileImage
                                      .toString(),
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
                                            "${inboxModel.restaurantName}",
                                            textAlign: TextAlign.start,
                                            style: TextStyle(
                                              fontFamily: AppThemeData.semiBold,
                                              fontSize: 16,
                                              color: AppThemeData.grey800,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          Constant.timestampToDate(
                                            inboxModel.createdAt!,
                                          ),
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
                                      "${inboxModel.lastMessage}",
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
                },
              ),
      ),
    );
  }
}
