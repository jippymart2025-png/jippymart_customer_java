import 'package:flutter/material.dart';
import '../models/models.dart';

class CommunityInfoScreen extends StatelessWidget {
  final CommunityData community;

  const CommunityInfoScreen({super.key, required this.community});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F8F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "Community Info",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xff14A44D), Color(0xff0B8A3B)],
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      "https://images.unsplash.com/photo-1460317442991-0ec209397118?w=800",
                      width: 82,
                      height: 82,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          community.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 15,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                community.location,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          "Established Jan 2023",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              "About Community",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 10),

            Text(
              "We are a friendly neighborhood community. Let's come together to save more and build stronger connections.",
              style: TextStyle(color: Colors.grey.shade700, height: 1.6),
            ),

            const SizedBox(height: 28),

            const Text(
              "Community Stats",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    Icons.groups,
                    community.families,
                    "Families",
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _StatCard(
                    Icons.receipt_long,
                    community.activeOrders,
                    "Active Orders",
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _StatCard(Icons.star, community.rating, "Rating"),
                ),
              ],
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Community Admins",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),

                TextButton(onPressed: () {}, child: const Text("View All")),
              ],
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 46,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (_, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundImage: NetworkImage(
                        "https://i.pravatar.cc/150?img=${index + 10}",
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Community Guidelines",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 8,
                    color: Colors.black.withOpacity(.05),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Expanded(child: Text("Be respectful and kind to everyone.")),

                  Icon(Icons.chevron_right),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String title;

  const _StatCard(this.icon, this.value, this.title);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(.05)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.green),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
