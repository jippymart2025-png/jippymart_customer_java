import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jippymart_customer/constant/send_notification.dart';
import 'package:jippymart_customer/models/conversation_model.dart';
import 'package:jippymart_customer/models/inbox_model.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ChatProvider extends ChangeNotifier {
  TextEditingController messageController = TextEditingController();

  final ScrollController scrollController = ScrollController();

  void initFunction() {
    if (scrollController.hasClients) {
      Timer(
        const Duration(milliseconds: 500),
        () =>
            scrollController.jumpTo(scrollController.position.maxScrollExtent),
      );
    }
    getArgument();
  }

  bool isLoading = true;
  String orderId = "";
  String customerId = "";
  String customerName = "";
  String customerProfileImage = "";
  String restaurantId = "";
  String restaurantName = "";
  String restaurantProfileImage = "";
  String token = "";
  String chatType = "";

  getArgument() {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      orderId = argumentData['orderId'];
      customerId = argumentData['customerId'];
      customerName = argumentData['customerName'];
      customerProfileImage = argumentData['customerProfileImage'] ?? "";
      restaurantId = argumentData['restaurantId'];
      restaurantName = argumentData['restaurantName'];
      restaurantProfileImage = argumentData['restaurantProfileImage'] ?? "";
      token = argumentData['token'];
      chatType = argumentData['chatType'];
    }
    isLoading = false;
    notifyListeners();
  }

  sendMessage(
    String message,
    Url? url,
    String videoThumbnail,
    String messageType,
  ) async {
    InboxModel inboxModel = InboxModel(
      lastSenderId: customerId,
      customerId: customerId,
      customerName: customerName,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      createdAt: Timestamp.now(),
      orderId: orderId,
      customerProfileImage: customerProfileImage,
      restaurantProfileImage: restaurantProfileImage,
      lastMessage: messageController.text,
      chatType: chatType,
    );

    if (chatType == "Driver") {
      await FireStoreUtils.addDriverInbox(inboxModel);
    } else {
      await FireStoreUtils.addRestaurantInbox(inboxModel);
    }

    ConversationModel conversationModel = ConversationModel(
      id: const Uuid().v4(),
      message: message,
      senderId: customerId,
      receiverId: restaurantId,
      createdAt: Timestamp.now(),
      url: url,
      orderId: orderId,
      messageType: messageType,
      videoThumbnail: videoThumbnail,
    );

    if (url != null) {
      if (url.mime.contains('image')) {
        conversationModel.message = "sent a message".tr;
      } else if (url.mime.contains('video')) {
        conversationModel.message = "Sent a video".tr;
      } else if (url.mime.contains('audio')) {
        conversationModel.message = "Sent a audio".tr;
      }
    }
    notifyListeners();
    if (chatType == "Driver") {
      await FireStoreUtils.addDriverChat(conversationModel);
    } else {
      await FireStoreUtils.addRestaurantChat(conversationModel);
    }
    await SendNotification.sendChatFcmMessage(
      customerName,
      conversationModel.message.toString(),
      token,
      {},
    );
  }

  final ImagePicker imagePicker = ImagePicker();
}
