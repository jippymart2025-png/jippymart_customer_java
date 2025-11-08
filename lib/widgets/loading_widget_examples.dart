import 'package:flutter/material.dart';
import 'package:jippymart_customer/widgets/app_loading_widget.dart';

/// **EXAMPLES OF HOW TO USE LOADING WIDGETS THROUGHOUT YOUR APP**
///
/// This file shows different ways to use the AppLoadingWidget
/// in various parts of your application.

class LoadingWidgetExamples extends StatelessWidget {
  const LoadingWidgetExamples({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loading Widget Examples')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // **1. BASIC USAGE**
            const Text(
              '1. Basic Usage:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const AppLoadingWidget(),
            const SizedBox(height: 30),

            // **2. SEARCH LOADING**
            const Text(
              '2. Search Loading:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const SearchLoadingWidget(),
            const SizedBox(height: 30),

            // **3. RESTAURANT LOADING**
            const Text(
              '3. Restaurant Loading:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const RestaurantLoadingWidget(),
            const SizedBox(height: 30),

            // **4. CUSTOM LOADING**
            const Text(
              '4. Custom Loading:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const AppLoadingWidget(
              title: "🍕 Loading Pizza Menu...",
              subtitle: "Getting the best deals for you",
              icon: Icons.local_pizza,
              backgroundColor: Colors.red,
              size: 70,
              showDots: true,
              showFunFact: true,
            ),
            const SizedBox(height: 30),

            // **5. SIMPLE LOADING**
            const Text(
              '5. Simple Loading:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const GeneralLoadingWidget(message: "🔄 Processing..."),
            const SizedBox(height: 30),

            // **6. DATA LOADING**
            const Text(
              '6. Data Loading:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const DataLoadingWidget(),
            const SizedBox(height: 30),

            // **7. ORDER LOADING**
            const Text(
              '7. Order Loading:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const OrderLoadingWidget(),
          ],
        ),
      ),
    );
  }
}

/// **USAGE EXAMPLES IN DIFFERENT SCENARIOS:**
