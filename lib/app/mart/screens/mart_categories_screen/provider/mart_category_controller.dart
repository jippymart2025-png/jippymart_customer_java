import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/models/mart_category_model.dart';
import 'package:jippymart_customer/services/mart_firestore_service.dart';

class MartCategoryProvider extends ChangeNotifier {
  final MartFirestoreService _firestoreService =
      Get.find<MartFirestoreService>();

  // Private list
  List<MartCategoryModel> _martCategories = [];
  List<MartCategoryModel> get martCategories => _martCategories;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadCategories({int limit = 100}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _martCategories =
          await _firestoreService.getCategories(limit: limit);
    } catch (e) {
      _error = e.toString();
      debugPrint("Error loading categories: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
