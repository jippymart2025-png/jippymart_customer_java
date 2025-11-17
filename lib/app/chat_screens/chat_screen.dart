import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jippymart_customer/app/chat_screens/full_screen_image_viewer.dart';
import 'package:jippymart_customer/app/chat_screens/full_screen_video_viewer.dart';
import 'package:jippymart_customer/app/chat_screens/provider/chat_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/conversation_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:jippymart_customer/widget/firebase_pagination/src/firestore_pagination.dart';
import 'package:jippymart_customer/widget/firebase_pagination/src/models/view_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'ChatVideoContainer.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.userId});

  final String? userId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  List<ConversationModel> _messages = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupScrollListener();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadMoreMessages();
      }
    });
  }

  Future<void> _loadMessages({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _isLoading = true;
      });
    }
    try {
      final ChatProvider controller = Provider.of<ChatProvider>(
        context,
        listen: false,
      );
      // Replace with your API call
      final response = await FireStoreUtils.getChatMessages(
        orderId: controller.orderId,
        chatType: controller.chatType?.toLowerCase() ?? 'driver',
        page: _currentPage,
      );

      if (response['status'] == true) {
        final data = response['data'];
        final List<dynamic> messagesData = data['data'];

        final List<ConversationModel> newMessages = messagesData
            .map((json) => ConversationModel.fromJson(json))
            .toList();

        setState(() {
          if (loadMore) {
            _messages.addAll(newMessages);
          } else {
            _messages = newMessages;
          }

          _hasMore = data['next_page_url'] != null;
          _isLoading = false;
        });

        // Scroll to bottom when new messages are loaded
        if (!loadMore) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading messages: $e');
    }
  }

  Future<void> _loadMoreMessages() async {
    if (!_hasMore || _isLoading) return;

    setState(() {
      _currentPage++;
    });

    await _loadMessages(loadMore: true);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppThemeData.surface,
            centerTitle: false,
            titleSpacing: 0,
            title: Text(
              controller.restaurantName,
              textAlign: TextAlign.start,
              style: TextStyle(
                fontFamily: AppThemeData.medium,
                fontSize: 16,
                color: AppThemeData.grey900,
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                  },
                  child: _isLoading && _messages.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _messages.isEmpty
                      ? Constant.showEmptyView(
                          message: "No Conversion found".tr,
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _messages.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _messages.length) {
                              return _hasMore
                                  ? const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : const SizedBox.shrink();
                            }

                            ConversationModel inboxModel = _messages[index];
                            return chatItemView(
                              inboxModel.senderId == widget.userId,
                              inboxModel,
                            );
                          },
                        ),
                ),
              ),
              Container(
                color: AppThemeData.grey50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: () {
                              onCameraClick(context, controller);
                            },
                            child: SvgPicture.asset(
                              "assets/icons/ic_picture_one.svg",
                            ),
                          ),
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: TextField(
                                textInputAction: TextInputAction.send,
                                keyboardType: TextInputType.text,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                controller: controller.messageController,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.only(
                                    top: 3,
                                    left: 10,
                                  ),
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  hintText: 'Type message here....'.tr,
                                ),
                                onSubmitted: (value) async {
                                  if (controller
                                      .messageController
                                      .text
                                      .isNotEmpty) {
                                    await controller.sendMessage(
                                      controller.messageController.text,
                                      null,
                                      '',
                                      'text',
                                    );
                                    // Reload messages after sending
                                    _currentPage = 1;
                                    await _loadMessages();
                                    _scrollToBottom();
                                    controller.messageController.clear();
                                  }
                                },
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              if (controller
                                  .messageController
                                  .text
                                  .isNotEmpty) {
                                await controller.sendMessage(
                                  controller.messageController.text,
                                  null,
                                  '',
                                  'text',
                                );
                                // Reload messages after sending
                                _currentPage = 1;
                                await _loadMessages();
                                _scrollToBottom();
                                controller.messageController.clear();
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(left: 10),
                              decoration: BoxDecoration(
                                color: AppThemeData.grey200,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: SvgPicture.asset(
                                  "assets/icons/ic_send.svg",
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget chatItemView(bool isMe, ConversationModel data) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
      child: isMe
          ? Align(
              alignment: Alignment.topRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  data.messageType == "text"
                      ? Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                            color: AppThemeData.primary300,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Text(
                            data.message.toString(),
                            style: const TextStyle(
                              fontFamily: AppThemeData.medium,
                              fontSize: 16,
                              color: AppThemeData.grey50,
                            ),
                          ),
                        )
                      : data.messageType == "image"
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Get.to(
                                    FullScreenImageViewer(
                                      imageUrl: data.url!.url,
                                    ),
                                  );
                                },
                                child: Hero(
                                  tag: data.url!.url,
                                  child: NetworkImageWidget(
                                    imageUrl: data.url!.url,
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : FloatingActionButton(
                          mini: true,
                          heroTag: data.id,
                          backgroundColor: AppThemeData.primary300,
                          onPressed: () {
                            Get.to(
                              FullScreenVideoViewer(
                                heroTag: data.id.toString(),
                                videoUrl: data.url!.url,
                              ),
                            );
                          },
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                          ),
                        ),
                  const SizedBox(height: 5),
                  Text(
                    DateFormat('MMM d, yyyy hh:mm aa').format(
                      DateTime.parse(data.createdAt.toString()).toLocal(),
                    ),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    data.messageType == "text"
                        ? Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                              color: AppThemeData.grey200,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Text(
                              data.message.toString(),
                              style: TextStyle(
                                fontFamily: AppThemeData.medium,
                                fontSize: 16,
                                color: AppThemeData.grey800,
                              ),
                            ),
                          )
                        : data.messageType == "image"
                        ? ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: 50,
                              maxWidth: 200,
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Get.to(
                                        FullScreenImageViewer(
                                          imageUrl: data.url!.url,
                                        ),
                                      );
                                    },
                                    child: Hero(
                                      tag: data.url!.url,
                                      child: NetworkImageWidget(
                                        imageUrl: data.url!.url,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : FloatingActionButton(
                            mini: true,
                            heroTag: data.id,
                            backgroundColor: AppThemeData.primary300,
                            onPressed: () {
                              Get.to(
                                FullScreenVideoViewer(
                                  heroTag: data.id.toString(),
                                  videoUrl: data.url!.url,
                                ),
                              );
                            },
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                            ),
                          ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  DateFormat(
                    'MMM d, yyyy hh:mm aa',
                  ).format(DateTime.parse(data.createdAt.toString()).toLocal()),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
    );
  }

  onCameraClick(BuildContext context, ChatProvider controller) {
    final action = CupertinoActionSheet(
      message: Text('Send Media'.tr, style: const TextStyle(fontSize: 15.0)),
      actions: <Widget>[
        CupertinoActionSheetAction(
          isDefaultAction: false,
          onPressed: () async {
            Get.back();
            XFile? image = await controller.imagePicker.pickImage(
              source: ImageSource.gallery,
            );
            if (image != null) {
              Url url = await FireStoreUtils.uploadChatImageToFireStorage(
                File(image.path),
                context,
              );
              await controller.sendMessage('', url, '', 'image');
              // Reload messages after sending
              _currentPage = 1;
              await _loadMessages();
              _scrollToBottom();
            }
          },
          child: Text("Choose image from gallery".tr),
        ),
        CupertinoActionSheetAction(
          isDefaultAction: false,
          onPressed: () async {
            Get.back();
            XFile? galleryVideo = await controller.imagePicker.pickVideo(
              source: ImageSource.gallery,
            );
            if (galleryVideo != null) {
              ChatVideoContainer? videoContainer =
                  await FireStoreUtils.uploadChatVideoToFireStorage(
                    context,
                    File(galleryVideo.path),
                  );
              if (videoContainer != null) {
                await controller.sendMessage(
                  '',
                  videoContainer.videoUrl,
                  videoContainer.thumbnailUrl,
                  'video',
                );
                // Reload messages after sending
                _currentPage = 1;
                await _loadMessages();
                _scrollToBottom();
              }
            }
          },
          child: Text("Choose video from gallery".tr),
        ),
        CupertinoActionSheetAction(
          isDestructiveAction: false,
          onPressed: () async {
            Get.back();
            XFile? image = await controller.imagePicker.pickImage(
              source: ImageSource.camera,
            );
            if (image != null) {
              Url url = await FireStoreUtils.uploadChatImageToFireStorage(
                File(image.path),
                context,
              );
              await controller.sendMessage('', url, '', 'image');
              // Reload messages after sending
              _currentPage = 1;
              await _loadMessages();
              _scrollToBottom();
            }
          },
          child: Text("Take a picture".tr),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text('Cancel'.tr),
        onPressed: () {
          Get.back();
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
