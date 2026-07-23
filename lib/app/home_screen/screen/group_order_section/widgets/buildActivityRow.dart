import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../themes/app_them_data.dart' show AppThemeData;
import '../model/create_group_orders_model.dart';

Widget buildActivityRow(GroupActivityEvent e) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(radius: 17, backgroundImage: NetworkImage(e.avatarUrl)),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: AppThemeData.medium,
                color: AppThemeData.grey800,
                fontSize: 13.5,
              ),
              children: [
                TextSpan(
                  text: '${e.memberName} ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: '${e.action} '),
                TextSpan(
                  text: e.detail,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        Text(
          e.timeAgo,
          style: TextStyle(
            fontFamily: AppThemeData.medium,
            color: e.isLive ? const Color(0xFF2EBD59) : AppThemeData.grey500,
            fontSize: 11.5,
          ),
        ),
      ],
    ),
  );
}
