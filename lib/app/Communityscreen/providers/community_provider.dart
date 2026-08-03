import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';

import '../models/listofcommunity.dart';
import 'community_service.dart';

final communityServiceProvider = Provider((ref) => CommunityService());

final communityProvider = FutureProvider<List<CommunityZoneModel>>((ref) async {
  final token = await SqlStorageConst.getAuthToken();
  if (token == null || token.trim().isEmpty) {
    throw Exception('Please log in to view communities');
  }

  return ref.read(communityServiceProvider).getCommunities(token);
});

final selectedCommunityProvider = StateProvider<CommunityZoneModel?>(
  (ref) => null,
);
