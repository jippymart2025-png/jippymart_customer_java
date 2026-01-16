import 'package:jippymart_customer/utils/utils/color_const.dart';
import 'package:flutter/material.dart';

import '../themes/app_them_data.dart';

String capitalize(String s) =>
    s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}' : s;

enum FilterType { distance, priceLowToHigh, priceHighToLow, rating }

class FilterBar extends StatelessWidget {
  final Set<FilterType> selectedFilters;
  final ValueChanged<FilterType> onFilterToggled;
  final List<String> availableFilters;
  final String? currentFilter;

  const FilterBar({
    Key? key,
    required this.selectedFilters,
    required this.onFilterToggled,
    required this.availableFilters,
    this.currentFilter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Map API filter names to FilterType enum and only show available ones
    final availableFilterTypes = _getAvailableFilterTypes();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: availableFilterTypes.map((filter) {
          final isSelected = _isFilterSelected(filter);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              backgroundColor: ColorConst.white,
              label: Text(
                _getFilterDisplayText(filter),
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : theme.textTheme.bodyMedium?.color,
                ),
              ),
              selected: isSelected,
              selectedColor: AppThemeData.primary300,
              onSelected: (_) => onFilterToggled(filter),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.transparent),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<FilterType> _getAvailableFilterTypes() {
    final availableTypes = <FilterType>[];

    for (var apiFilter in availableFilters) {
      switch (apiFilter) {
        case 'distance':
          availableTypes.add(FilterType.distance);
          break;
        case 'rating':
          availableTypes.add(FilterType.rating);
          break;
      }
    }

    return availableTypes;
  }

  bool _isFilterSelected(FilterType filter) {
    switch (filter) {
      case FilterType.distance:
        return currentFilter == 'distance';
      case FilterType.rating:
        return currentFilter == 'rating';
      case FilterType.priceLowToHigh:
      case FilterType.priceHighToLow:
        return false; // These are not supported by API
    }
  }

  String _getFilterDisplayText(FilterType filter) {
    switch (filter) {
      case FilterType.distance:
        return 'Distance';
      case FilterType.rating:
        return 'Rating';
      case FilterType.priceLowToHigh:
        return 'Price: Low to High';
      case FilterType.priceHighToLow:
        return 'Price: High to Low';
    }
  }
}
