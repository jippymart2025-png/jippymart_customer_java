import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jippymart_customer/utils/utils/color_const.dart';

import '../../models/models.dart';

class OrderCard extends StatelessWidget {
  final GroupOrder order;

  const OrderCard({required this.order, required bool compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// FOOD IMAGE
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: Image.network(
                  'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800',
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 90,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    height: 90,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.fastfood, size: 40),
                  ),
                ),
              ),

              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${order.joinedCount}/30 Joined",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                // const SizedBox(height: 4),
                Text(
                  order.restaurant,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.discount,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),

                    const Spacer(),

                    Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),

                    const SizedBox(width: 4),

                    Text(
                      "2h left",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey.shade600),

                    const SizedBox(width: 4),

                    Text(
                      "${order.joinedCount} joined",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const Spacer(),

                    SizedBox(
                      height: 34,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          "Join Order",
                          style: TextStyle(
                            color: ColorConst.blackColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
