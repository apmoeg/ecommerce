import 'package:flutter_sixvalley_ecommerce/interface/repo_interface.dart';

abstract class ShopRepositoryInterface extends RepositoryInterface{
  Future<dynamic> getMoreStore();
  Future<dynamic> getSellerList(String type, int offset);
  Future<dynamic> getClearanceShopProductList(String type, String offset, String sellerId);
  Future<dynamic> getClearanceSearchProduct(String sellerId, String offset, String productId, {String search = '', String? categoryIds, String? brandIds, String? authorIds, String? publishingIds, String? productType, String? offerType});
}