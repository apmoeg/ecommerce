abstract class ShopServiceInterface{
  Future<dynamic> getMoreStore();
  Future<dynamic> getSellerList(String type, int offset);
  Future<dynamic> getClearanceShopProductList(String type, String offset, String sellerId);
  Future<dynamic> get(String id);
  Future<dynamic> getClearanceSearchProduct(String sellerId, String offset, String productId, {String search = '', String? categoryIds, String? brandIds,  String? authorIds, String? publishingIds, String? productType, String? offerType});
}