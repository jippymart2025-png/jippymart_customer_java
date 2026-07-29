import 'package:jippymart_customer/app/edit_profile_screen/edit_profile_screen.dart';
import 'package:jippymart_customer/app/profile_screen/provider/my_profile_provider.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/utils/network_image_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../edit_profile_screen/provider/edit_profile_provider.dart';

Widget buildSliverHeader(MyProfileProvider controller, context) {
  final user = Constant.userModel;
  final name = user?.firstName ?? 'Guest User';
  final phone = user?.phoneNumber ?? 'Not logged in';
  final email = user?.email ?? '';
  final initials = name.isNotEmpty
      ? name
            .trim()
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase()
      : 'G';

  return SliverAppBar(
    expandedHeight: 150,
    pinned: true,
    backgroundColor: Color(0xFFFF4E1F),
    elevation: 0,
    leading: const SizedBox.shrink(),
    flexibleSpace: FlexibleSpaceBar(
      background: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ZColors.kGradStart, Color(0xFFFF4E1F), ZColors.kGradEnd],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top label
                // const Text(
                //   'My Account',
                //   style: TextStyle(
                //     color: Colors.white70,
                //     fontSize: 13,
                //     fontWeight: FontWeight.w500,
                //     letterSpacing: 0.5,
                //   ),
                // ),
                const SizedBox(height: 16),
                // Avatar + info row
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _buildAvatar(user, initials),
                    ),
                    const SizedBox(width: 16),
                    // Name + phone
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (phone.isNotEmpty && phone != 'Not logged in')
                            Text(
                              phone,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          if (email.isNotEmpty)
                            Text(
                              email,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    // Edit button
                    if (user != null)
                      GestureDetector(
                        onTap: () {
                          context.read<EditProfileProvider>().initFunction();
                          Get.to(() => const EditProfileScreen());
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      collapseMode: CollapseMode.pin,
    ),
    // Collapsed title
    // title: const Text(
    //   'My Account',
    //   style: TextStyle(
    //     color: Colors.white,
    //     fontSize: 18,
    //     fontWeight: FontWeight.w700,
    //   ),
    // ),
    centerTitle: false,
  );
}

Widget _buildAvatar(dynamic user, String initials) {
  // ⚠️ Change 'photo' below to match your actual UserModel field name
  // e.g. if your model has `userModel.photoURL` → use user?.photoURL
  String? photoUrl;
  try {
    // ignore: avoid_dynamic_calls
    final val = user?.photo;
    if (val is String && val.isNotEmpty) photoUrl = val;
  } catch (_) {}

  if (photoUrl != null) {
    return ClipOval(
      child: NetworkImageWidget(
        imageUrl: photoUrl,
        width: 68,
        height: 68,
        fit: BoxFit.cover,
        errorWidget: _avatarInitials(initials),
      ),
    );
  }
  return _avatarInitials(initials);
}

Widget _avatarInitials(String initials) {
  return Center(
    child: Text(
      initials,
      style: const TextStyle(
        color: ZColors.primary,
        fontSize: 24,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
