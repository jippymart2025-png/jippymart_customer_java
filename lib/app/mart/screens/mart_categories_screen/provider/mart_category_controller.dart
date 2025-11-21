import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/models/mart_category_model.dart';
import 'package:jippymart_customer/services/mart_firestore_service.dart';

class MartCategoryProvider extends ChangeNotifier {
  final MartFirestoreService _firestoreService =
      Get.find<MartFirestoreService>();
  List<MartCategoryModel> martCategories = [];

  Future<void> loadCategories() async {
    print(" loadCategories");
    martCategories = await _firestoreService.getCategories(limit: 100);
    print("loadCategories length ${martCategories.length} ");
    notifyListeners();
  }

  void initFunction() {
    loadCategories();
  }
}
