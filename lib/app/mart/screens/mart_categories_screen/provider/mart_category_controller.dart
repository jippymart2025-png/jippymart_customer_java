import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:jippymart_customer/models/mart_category_model.dart';
import 'package:jippymart_customer/services/mart_firestore_service.dart';

class MartCategoryProvider extends ChangeNotifier {
  MartFirestoreService? _firestoreService;

  MartCategoryProvider() {
    // Safe initialization - handle case where service might not be registered
    try {
      _firestoreService = Get.find<MartFirestoreService>();
    } catch (e) {
      debugPrint("⚠️ [MART_CATEGORY] MartFirestoreService not found: $e");
      _firestoreService = null;
    }
  }

  // Private list
  List<MartCategoryModel> _martCategories = [];
  List<MartCategoryModel> get martCategories => _martCategories;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadCategories({int limit = 100}) async {
    // Check if service is available
    if (_firestoreService == null) {
      _error = "Service not available. Please restart the app.";
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _martCategories =
          await _firestoreService!.getCategories(limit: limit);
    } catch (e) {
      _error = e.toString();
      debugPrint("❌ [MART_CATEGORY] Error loading categories: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
