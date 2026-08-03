import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import '../../../utils/utils/sql_storage_const.dart';
import '../providers/community_provider.dart';
import 'home_screen.dart';

class CommunityListScreen extends ConsumerStatefulWidget {
  const CommunityListScreen({super.key});

  @override
  ConsumerState<CommunityListScreen> createState() =>
      _CommunityListScreenState();
}

class _CommunityListScreenState extends ConsumerState<CommunityListScreen> {
  final TextEditingController searchController = TextEditingController();

  String search = "";

  @override
  Widget build(BuildContext context) {
    final communities = ref.watch(communityProvider);

    return Scaffold(
      backgroundColor: const Color(0xffF6F8FC),

      body: SafeArea(
        child: Column(
          children: [
            /// HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff1E3A8A), Color(0xff2563EB)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Select Community",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) {
                        setState(() {
                          search = value.toLowerCase();
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: "Search community...",
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.search_rounded),
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: communities.when(
                loading: () => const Center(child: CircularProgressIndicator()),

                error: (e, _) => Center(child: Text(e.toString())),

                data: (list) {
                  final filtered = list
                      .where((c) => c.zoneName.toLowerCase().contains(search))
                      .toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        "No Communities Found",
                        style: TextStyle(fontSize: 18),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.refresh(communityProvider.future);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(18),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final community = filtered[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              ref
                                      .read(selectedCommunityProvider.notifier)
                                      .state =
                                  community;

                              Get.to(() => const HomeScreen());
                            },
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(.08),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      color: const Color(0xffEAF2FF),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Image.network(
                                      "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=1200",
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;

                                            return const Center(
                                              child: SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            );
                                          },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Center(
                                              child: Icon(
                                                Icons.apartment,
                                                size: 30,
                                                color: Color(0xff2563EB),
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          community.zoneName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),

                                        const SizedBox(height: 6),

                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_city,
                                              size: 16,
                                              color: Colors.grey,
                                            ),

                                            const SizedBox(width: 5),

                                            Text(
                                              community.zoneType,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 10),

                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                              ),
                                              child: const Text(
                                                "Active",
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(
                                    height: 40,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        try {
                                          final customerId =
                                              await SqlStorageConst.getFirebaseId();

                                          final success = await ref
                                              .read(communityServiceProvider)
                                              .joinCommunity(
                                                customerId: int.parse(
                                                  customerId!,
                                                ),
                                                communityId: community.zoneId,
                                              );

                                          if (!success) return;

                                          ref
                                                  .read(
                                                    selectedCommunityProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              community;

                                          Get.off(() => const HomeScreen());

                                          Get.snackbar(
                                            "Success",
                                            "Joined ${community.zoneName}",
                                            snackPosition: SnackPosition.BOTTOM,
                                          );
                                        } catch (e) {
                                          Get.snackbar(
                                            "Error",
                                            e.toString(),
                                            snackPosition: SnackPosition.BOTTOM,
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xff2563EB,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text("Join"),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
