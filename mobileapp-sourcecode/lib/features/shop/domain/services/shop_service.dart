import 'package:flutter_sixvalley_ecommerce/features/shop/domain/repositories/shop_repository_interface.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/domain/services/shop_service_interface.dart';

class ShopService implements ShopServiceInterface{
  ShopRepositoryInterface shopRepositoryInterface;

  ShopService({required this.shopRepositoryInterface});

  @override
  Future getMoreStore() async{
    return await shopRepositoryInterface.getMoreStore();
  }

  @override
  Future getSellerList(String type, int offset) async{
    return await shopRepositoryInterface.getSellerList(type, offset);
  }

  @override
  Future getClearanceShopProductList(String type, String offset, String sellerId) async{
    return await shopRepositoryInterface.getClearanceShopProductList(type, offset, sellerId);
  }

  @override
  Future get(String id) async {
    return await shopRepositoryInterface.get(id);
  }

  @override
  Future getClearanceSearchProduct(String sellerId, String offset, String productId, {String search = '', String? categoryIds, String? brandIds, String? authorIds, String? publishingIds, String? productType, String? offerType}) async {
    return await shopRepositoryInterface.getClearanceSearchProduct(sellerId, offset, productId, search: search, categoryIds: categoryIds, brandIds: brandIds, authorIds: authorIds, publishingIds: publishingIds, productType: productType, offerType: 'clearance_sale');
  }

}