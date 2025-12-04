import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/models/order_model.dart';
import 'package:jippymart_customer/models/product_model.dart';
import 'package:jippymart_customer/models/rating_model.dart';
import 'package:jippymart_customer/models/review_attribute_model.dart';
import 'package:jippymart_customer/models/vendor_category_model.dart';
import 'package:jippymart_customer/models/vendor_model.dart';
import 'package:jippymart_customer/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jippymart_customer/utils/utils/sql_storage_const.dart';

class RateProductProvider extends ChangeNotifier {
  bool isLoading = true;

  TextEditingController commentController = TextEditingController();

  OrderModel orderModel = OrderModel();
  String productId = "";
  RatingModel ratingModel = RatingModel();
  ProductModel productModel = ProductModel();
  VendorModel vendorModel = VendorModel();
  VendorCategoryModel vendorCategoryModel = VendorCategoryModel();

  List<ReviewAttributeModel> reviewAttributeList = <ReviewAttributeModel>[];

  double ratings = 0.0;

  Map<String, dynamic> reviewAttribute = <String, dynamic>{};
  Map<String, dynamic> reviewProductAttributes = <String, dynamic>{};
  double vendorReviewSum = 0.0;
  double vendorReviewCount = 0.0;
  double productReviewSum = 0.0;
  double productReviewCount = 0.0;

  initFunction({
    required OrderModel orderModel,
    required String productId,
  }) async {
    this.orderModel = orderModel;
    this.productId = productId;

    print("Product ID received: $productId"); // Debug log
    await FireStoreUtils.getOrderReviewsByID(
      orderModel.id.toString(),
      productId,
    ).then((value) {
      if (value != null) {
        ratingModel = value;
        ratings = value.rating ?? 0.0;
        commentController.text = value.comment.toString();
        reviewAttribute = value.reviewAttributes ?? {};
        images.clear();
        if (value.photos != null && value.photos!.isNotEmpty) {
          images.addAll(value.photos!.map((photo) => photo.toString()));
        }
        notifyListeners();
      }
    });

    await FireStoreUtils.getProductById(productId.split('~').first).then((
      value,
    ) {
      if (value != null) {
        productModel = value;
        if (ratingModel.id != null) {
          productReviewCount = value.reviewsCount! - 1;
          productReviewSum = value.reviewsSum! - ratings;

          if (value.reviewAttributes != null) {
            value.reviewAttributes!.forEach((key, value) {
              ReviewsAttribute reviewsAttributeModel =
                  ReviewsAttribute.fromJson(value);
              reviewsAttributeModel.reviewsCount =
                  reviewsAttributeModel.reviewsCount! - 1;
              reviewsAttributeModel.reviewsSum =
                  reviewsAttributeModel.reviewsSum! - reviewAttribute[key];
              reviewProductAttributes.addEntries([
                MapEntry(key, reviewsAttributeModel.toJson()),
              ]);
            });
          }
        } else {
          productReviewCount = double.parse(value.reviewsCount.toString());
          productReviewSum = double.parse(value.reviewsSum.toString());
          if (value.reviewAttributes != null) {
            reviewProductAttributes = value.reviewAttributes!;
          }
        }
      }
      notifyListeners();
    });

    await FireStoreUtils.getVendorById(productModel.vendorID.toString()).then((
      value,
    ) {
      if (value != null) {
        vendorModel = value;
        if (ratingModel.id != null) {
          vendorReviewCount = value.reviewsCount! - 1;
          vendorReviewSum = value.reviewsSum! - ratings;
        } else {
          vendorReviewCount = double.parse(value.reviewsCount.toString());
          vendorReviewSum = double.parse(value.reviewsSum.toString());
        }
      }
      notifyListeners();
    });

    await FireStoreUtils.getVendorCategoryByCategoryId(
      productModel.categoryID.toString(),
    ).then((value) async {
      if (value != null) {
        vendorCategoryModel = value;
        for (var element in vendorCategoryModel.reviewAttributes!) {
          await FireStoreUtils.getVendorReviewAttribute(element).then((value) {
            reviewAttributeList.add(value!);
          });
        }
      }
      notifyListeners();
    });
    isLoading = false;
    notifyListeners();
  }

  // saveRating() async {
  //   if (ratings != 0.0) {
  //     ShowToastDialog.showLoader("Please wait".tr);
  //     productModel.reviewsCount = productReviewCount + 1;
  //     productModel.reviewsSum = productReviewSum + ratings;
  //     productModel.reviewAttributes = reviewProductAttributes;
  //     vendorModel.reviewsCount = vendorReviewCount + 1;
  //     vendorModel.reviewsSum = vendorReviewSum + ratings;
  //     if (reviewProductAttributes.isEmpty) {
  //       reviewAttribute.forEach((key, value) {
  //         ReviewsAttribute reviewsAttributeModel = ReviewsAttribute(
  //           reviewsCount: 1,
  //           reviewsSum: value,
  //         );
  //         reviewProductAttributes.addEntries([
  //           MapEntry(key, reviewsAttributeModel.toJson()),
  //         ]);
  //       });
  //     } else {
  //       reviewProductAttributes.forEach((key, value) {
  //         ReviewsAttribute reviewsAttributeModel = ReviewsAttribute.fromJson(
  //           value,
  //         );
  //         reviewsAttributeModel.reviewsCount =
  //             reviewsAttributeModel.reviewsCount! + 1;
  //         reviewsAttributeModel.reviewsSum =
  //             reviewsAttributeModel.reviewsSum! + reviewAttribute[key];
  //         reviewProductAttributes.addEntries([
  //           MapEntry(key, reviewsAttributeModel.toJson()),
  //         ]);
  //       });
  //     }
  //     print("ratingProduct } ");
  //     final userId = await SqlStorageConst.getFirebaseId();
  //     for (int i = 0; i < images.length; i++) {
  //       if (images[i].runtimeType == XFile) {
  //         String url = await Constant.uploadUserImageToFireStorage(
  //           File(images[i].path),
  //           "profileImage/$userId",
  //           File(images[i].path).path.split('/').last,
  //         );
  //         images.removeAt(i);
  //         images.insert(i, url);
  //       }
  //     }
  //     RatingModel ratingProduct = RatingModel(
  //       productId: productId,
  //       comment: commentController.text,
  //       photos: images,
  //       rating: ratings,
  //       customerId: userId,
  //       id: ratingModel.id ?? Constant.getUuid(),
  //       orderId: orderModel.id,
  //       vendorId: productModel.vendorID,
  //       createdAt: Timestamp.now().toString(),
  //       uname: Constant.userModel!.fullName(),
  //       profile: Constant.userModel!.profilePictureURL,
  //       reviewAttributes: reviewAttribute,
  //     );
  //     print("ratingProduct2 ${ratingProduct.toJson()} ");
  //     await FireStoreUtils.setRatingModel(ratingProduct);
  //     await FireStoreUtils.setProduct(productModel);
  //     ShowToastDialog.closeLoader();
  //     Get.back();
  //   } else {
  //     ShowToastDialog.showToast("Please add rate for food item.".tr);
  //   }
  //   notifyListeners();
  // }
  saveRating() async {
    if (ratings != 0.0) {
      ShowToastDialog.showLoader("Please wait".tr);

      try {
        // Prepare data updates
        productModel.reviewsCount = productReviewCount + 1;
        productModel.reviewsSum = productReviewSum + ratings;
        productModel.reviewAttributes = reviewProductAttributes;
        vendorModel.reviewsCount = vendorReviewCount + 1;
        vendorModel.reviewsSum = vendorReviewSum + ratings;

        // Handle review attributes
        if (reviewProductAttributes.isEmpty) {
          reviewAttribute.forEach((key, value) {
            ReviewsAttribute reviewsAttributeModel = ReviewsAttribute(
              reviewsCount: 1,
              reviewsSum: value,
            );
            reviewProductAttributes.addEntries([
              MapEntry(key, reviewsAttributeModel.toJson()),
            ]);
          });
        } else {
          reviewProductAttributes.forEach((key, value) {
            ReviewsAttribute reviewsAttributeModel = ReviewsAttribute.fromJson(
              value,
            );
            reviewsAttributeModel.reviewsCount =
                reviewsAttributeModel.reviewsCount! + 1;
            reviewsAttributeModel.reviewsSum =
                reviewsAttributeModel.reviewsSum! + (reviewAttribute[key] ?? 0);
            reviewProductAttributes[key] = reviewsAttributeModel.toJson();
          });
        }

        // Get user ID
        final userId = await SqlStorageConst.getFirebaseId();

        // Process images - convert XFiles to URLs
        List<String> photoUrls = [];

        for (var image in images) {
          if (image.runtimeType == XFile) {
            try {
              // Upload new image
              String url = await Constant.uploadUserImageToFireStorage(
                File((image as XFile).path),
                "reviews/$userId",
                "${DateTime.now().millisecondsSinceEpoch}_${(image).path.split('/').last}",
              );
              photoUrls.add(url);
            } catch (e) {
              print("Error uploading image: $e");
              // Continue with other images even if one fails
              continue;
            }
          } else if (image is String) {
            // Already a URL, add directly
            photoUrls.add(image);
          }
        }

        // Create or update rating model
        RatingModel ratingProduct = RatingModel(
          productId: productId,
          comment: commentController.text.trim(),
          photos: photoUrls,
          // Use processed URLs only
          rating: ratings,
          customerId: userId,
          id: ratingModel.id?.isEmpty ?? true
              ? Constant.getUuid()
              : ratingModel.id!,
          orderId: orderModel.id,
          vendorId: productModel.vendorID,
          createdAt: ratingModel.id == null
              ? Timestamp.now().toString()
              : ratingModel.createdAt,
          // Keep original create date
          // updatedAt: Timestamp.now().toString(),
          // Add update timestamp
          uname: Constant.userModel!.fullName(),
          profile: Constant.userModel!.profilePictureURL,
          reviewAttributes: reviewAttribute.isNotEmpty ? reviewAttribute : null,
        );

        // Save to Firestore
        bool? isSaved = await FireStoreUtils.setRatingModel(ratingProduct);

        if (isSaved == true) {
          // Update product
          await FireStoreUtils.setProduct(productModel);

          // Optionally update vendor
          // await FireStoreUtils.updateVendor(vendorModel);

          ShowToastDialog.closeLoader();
          Get.back();
          ShowToastDialog.showToast("Review submitted successfully!".tr);
        } else {
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast(
            "Failed to save review. Please try again.".tr,
          );
        }
      } catch (e) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("Error: ${e.toString()}".tr);
        print("Save rating error: $e");
      }
    } else {
      ShowToastDialog.showToast("Please add rate for food item.".tr);
    }
    notifyListeners();
  }

  final ImagePicker _imagePicker = ImagePicker();
  List images = <dynamic>[];

  Future pickFile({required ImageSource source}) async {
    try {
      XFile? image = await _imagePicker.pickImage(source: source);
      if (image == null) return;

      // Check if we're updating an existing review
      if (ratingModel.id != null) {
        // For updates, we need to upload immediately or mark as new
        ShowToastDialog.showLoader("Uploading image...".tr);
        try {
          final userId = await SqlStorageConst.getFirebaseId();
          String url = await Constant.uploadUserImageToFireStorage(
            File(image.path),
            "reviews/$userId",
            "${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}",
          );
          images.add(url); // Add URL directly
          ShowToastDialog.closeLoader();
        } catch (e) {
          ShowToastDialog.closeLoader();
          ShowToastDialog.showToast("Failed to upload image".tr);
          return;
        }
      } else {
        images.add(image);
      }
      notifyListeners();
      Get.back();
    } on PlatformException catch (e) {
      ShowToastDialog.showToast("Failed to Pick : \n $e");
    }
  }

  // Future pickFile({required ImageSource source}) async {
  //   try {
  //     XFile? image = await _imagePicker.pickImage(source: source);
  //     if (image == null) return;
  //     images.add(image);
  //     notifyListeners();
  //     Get.back();
  //   } on PlatformException catch (e) {
  //     ShowToastDialog.showToast("Failed to Pick : \n $e");
  //   }
  // }
}
