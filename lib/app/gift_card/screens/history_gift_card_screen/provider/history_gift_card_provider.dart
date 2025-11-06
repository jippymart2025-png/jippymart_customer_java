import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/gift_cards_order_model.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;

class HistoryGiftCardProvider extends ChangeNotifier {
  RxList<GiftCardsOrderModel> giftCardsOrderList = <GiftCardsOrderModel>[].obs;
  RxBool isLoading = true.obs;

  void initFunction() {
    getData();
  }
  getData() async {
    await FireStoreUtils.getGiftHistory().then((value) {
      giftCardsOrderList.value = value;
    });
    isLoading.value = false;
  }
  updateList(int index) {
    GiftCardsOrderModel giftCardsOrderModel = giftCardsOrderList[index];
    giftCardsOrderModel.isPasswordShow = giftCardsOrderModel.isPasswordShow == true ? false : true;
    giftCardsOrderList.removeAt(index);
    giftCardsOrderList.insert(index, giftCardsOrderModel);
    notifyListeners();
  }

  Future<void> share(String giftCode, String giftPin, String msg, String amount, Timestamp date) async {
    await SharePlus.instance.share(
      ShareParams(
        text: "${'Gift Code :'.tr} $giftCode\n${'Gift Pin :'.tr} $giftPin\n${'Price :'.tr} ${Constant.amountShow(amount: amount)}\n${'Expire Date :'.tr} ${date.toDate()}\n\n${'Message'.tr} : $msg",
      ),
    );
  }
}
