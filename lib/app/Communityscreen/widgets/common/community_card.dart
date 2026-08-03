import 'package:flutter/material.dart';

import '../../models/listofcommunity.dart';

class CommunityCard extends StatelessWidget {
  final CommunityZoneModel community;
  final VoidCallback onTap;

  const CommunityCard({
    super.key,
    required this.community,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(child: Icon(Icons.apartment)),
        title: Text(
          community.zoneName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(community.zoneType),
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }
}
