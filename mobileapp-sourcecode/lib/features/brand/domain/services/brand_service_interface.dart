abstract class BrandServiceInterface{
  Future<dynamic> getSellerWiseBrandList(int sellerId);
  Future<dynamic> getBrandList(int offset);
  Future<dynamic> getList();
}