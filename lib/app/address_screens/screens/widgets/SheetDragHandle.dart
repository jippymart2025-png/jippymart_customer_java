import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/app/address_screens/screens/widgets/tokan.dart';

class SheetDragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Tokens.sp12),
      child: Center(
        child: Container(
          width: 44,
          height: 5,
          decoration: BoxDecoration(
            color: Tokens.cardBorder,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
