import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RedeemGiftCardProvider extends ChangeNotifier {
  Rx<TextEditingController> giftCodeController = TextEditingController().obs;
  Rx<TextEditingController> giftPinController = TextEditingController().obs;

}
