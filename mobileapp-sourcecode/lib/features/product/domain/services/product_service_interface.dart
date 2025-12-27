import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/enums/product_type.dart';

abstract class ProductServiceInterface{
  Future<dynamic> getFilteredProductList(BuildContext context,String offset, ProductType productType, String? title);
  Future<dynamic> getBrandOrCategoryProductList({required bool isBrand, required int id, required int offset});
  Future<dynamic> getRelatedProductList(String id);
  Future<dynamic> getFeaturedProductList(String offset);
  Future<dynamic> getLatestProductList(String offset);
  Future<dynamic> getRecommendedProduct();
  Future<dynamic> getMostDemandedProduct();
  Future<dynamic> getFindWhatYouNeed();
  Future<dynamic> getJustForYouProductList();
  Future<dynamic> getMostSearchingProductList(int offset);
  Future<dynamic> getHomeCategoryProductList();
  Future<dynamic> getClearanceAllProductList(String offset);
  Future<dynamic> getClearanceSearchProducts(String query, String? categoryIds, String? brandIds, String? authorIds, String? publishingIds, String? sort, String? priceMin, String? priceMax, int offset, String? productType, String? offerType);
}