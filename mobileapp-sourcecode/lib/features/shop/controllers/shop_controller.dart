import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/data/local/cache_response.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/domain/models/more_store_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/domain/models/seller_info_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/domain/models/seller_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/shop/domain/services/shop_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class ShopController extends ChangeNotifier {
  final ShopServiceInterface? shopServiceInterface;
  ShopController({required this.shopServiceInterface});

  String? _searchText;
  String? get searchText => _searchText;

  String? shopName;
  void setShopName(String? name, {bool notify = true}){
    shopName = name;
    if(notify){
      notifyListeners();
    }
  }


  int shopMenuIndex = 0;
  void setMenuItemIndex(int index, {bool notify = true}){
    shopMenuIndex = index;
    if(notify){
      notifyListeners();
    }
  }


  SellerInfoModel? sellerInfoModel ;
  Future<void> getSellerInfo(String sellerId) async {
    ApiResponse apiResponse = await shopServiceInterface!.get(sellerId);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      sellerInfoModel = SellerInfoModel.fromJson(apiResponse.response!.data);
    } else {
      ApiChecker.checkApi( apiResponse);
    }
    notifyListeners();
  }



  bool isLoading = false;
  List<MostPopularStoreModel> moreStoreList =[];
  Future<ApiResponse> getMoreStore() async {
    var localData =  await database.getCacheResponseById(AppConstants.moreStore);

    if(localData != null) {
      final data = jsonDecode(localData.response);

      data.forEach((store)=> moreStoreList.add(MostPopularStoreModel.fromJson(store)));
      notifyListeners();
    }

    moreStoreList = [];
    isLoading = true;
    ApiResponse apiResponse = await shopServiceInterface!.getMoreStore();
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      apiResponse.response?.data.forEach((store)=> moreStoreList.add(MostPopularStoreModel.fromJson(store)));

      if(localData != null) {
        await database.updateCacheResponse(AppConstants.moreStore, CacheResponseCompanion(
          endPoint: const Value(AppConstants.moreStore),
          header: Value(jsonEncode(apiResponse.response!.headers.map)),
          response: Value(jsonEncode(apiResponse.response!.data)),
        ));
      } else {
        await database.insertCacheResponse(
          CacheResponseCompanion(
            endPoint: const Value(AppConstants.moreStore),
            header: Value(jsonEncode(apiResponse.response!.headers.map)),
            response: Value(jsonEncode(apiResponse.response!.data)),
          ),
        );
      }


    } else {
      isLoading = false;
      ApiChecker.checkApi( apiResponse);
    }
    notifyListeners();
    return apiResponse;
  }
  String sellerType = "all";
  String sellerTypeTitle = "all_seller";
  void setSellerType(String type, {bool notify = true}){
    sellerType = type;
    sellerModel = null;
    if(sellerType == "top"){
      sellerTypeTitle = "top_seller";
    }
    else if(sellerType == "new"){
      sellerTypeTitle = "new_seller";
    }else{
      sellerTypeTitle = "all_seller";
    }
    getTopSellerList(true, 1,type: sellerType);
    if(notify){
      notifyListeners();
    }
  }

  SellerModel? sellerModel;
  Future<void> getTopSellerList(bool reload, int offset, {required String type}) async {

    var localData =  await database.getCacheResponseById("${AppConstants.sellerList}$type");

    if(localData != null) {
      sellerModel = SellerModel.fromJson(jsonDecode(localData.response));
      notifyListeners();
    }

      ApiResponse apiResponse = await shopServiceInterface!.getSellerList(type, offset);
      if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
        if(offset == 1){
          sellerModel = null;
          // SellerModel.fromJson(apiResponse.response?.data);
          sellerModel = SellerModel.fromJson(apiResponse.response?.data);
        }else{
          sellerModel?.sellers?.addAll(SellerModel.fromJson(apiResponse.response!.data).sellers??[]);
          sellerModel?.offset  = (SellerModel.fromJson(apiResponse.response!.data).offset!);
          sellerModel?.totalSize  = (SellerModel.fromJson(apiResponse.response!.data).totalSize!);
        }

        if (localData != null) {
          await database.updateCacheResponse("${AppConstants.sellerList}$type", CacheResponseCompanion(
            endPoint: Value("${AppConstants.sellerList}$type"),
            header: Value(jsonEncode(apiResponse.response!.headers.map)),
            response: Value(jsonEncode(apiResponse.response!.data)),
          ));
        } else {
          await database.insertCacheResponse(
            CacheResponseCompanion(
              endPoint: Value("${AppConstants.sellerList}$type"),
              header: Value(jsonEncode(apiResponse.response!.headers.map)),
              response: Value(jsonEncode(apiResponse.response!.data)),
            ),
          );
        }
      }
    notifyListeners();
  }

  SellerModel? allSellerModel;
  Future<void> getAllSellerList(bool reload, int offset, {required String type}) async {

    var localData =  await database.getCacheResponseById("${AppConstants.sellerList}$type");

    if(localData != null) {
      allSellerModel = SellerModel.fromJson(jsonDecode(localData.response));
      notifyListeners();
    }


    ApiResponse apiResponse = await shopServiceInterface!.getSellerList('all', offset);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      if(offset == 1){
        allSellerModel = null;
        // SellerModel.fromJson(apiResponse.response?.data);
        allSellerModel = SellerModel.fromJson(apiResponse.response?.data);

        if (localData != null) {
          await database.updateCacheResponse("${AppConstants.sellerList}$type", CacheResponseCompanion(
            endPoint: Value("${AppConstants.sellerList}$type"),
            header: Value(jsonEncode(apiResponse.response!.headers.map)),
            response: Value(jsonEncode(apiResponse.response!.data)),
          ));
        } else {
          await database.insertCacheResponse(
            CacheResponseCompanion(
              endPoint: Value("${AppConstants.sellerList}$type"),
              header: Value(jsonEncode(apiResponse.response!.headers.map)),
              response: Value(jsonEncode(apiResponse.response!.data)),
            ),
          );
        }
      }else{
        allSellerModel?.sellers?.addAll(SellerModel.fromJson(apiResponse.response!.data).sellers??[]);
        allSellerModel?.offset  = (SellerModel.fromJson(apiResponse.response!.data).offset!);
        allSellerModel?.totalSize  = (SellerModel.fromJson(apiResponse.response!.data).totalSize!);
      }
    }
    notifyListeners();
  }





  ProductModel? clearanceProductModel;
  Future<void> getClearanceShopProductList(String type, String offset, String sellerId, {bool reload = false}) async {

    var localData =  await database.getCacheResponseById("${AppConstants.clearanceShopProductUri}$sellerId/products?guest_id=1&limit=10&offset=$offset&offer_type=$type");

    if(localData != null) {
      clearanceProductModel = ProductModel.fromJson(jsonDecode(localData.response));
      notifyListeners();
    }

    ApiResponse apiResponse = await shopServiceInterface!.getClearanceShopProductList(type, offset, sellerId);

    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      if(offset == '1'){
        clearanceProductModel = null;
        // SellerModel.fromJson(apiResponse.response?.data);
        clearanceProductModel = ProductModel.fromJson(apiResponse.response?.data);
      }else{
        clearanceProductModel?.products?.addAll(ProductModel.fromJson(apiResponse.response!.data).products??[]);
        clearanceProductModel?.offset  = (ProductModel.fromJson(apiResponse.response!.data).offset!);
        clearanceProductModel?.totalSize  = (ProductModel.fromJson(apiResponse.response!.data).totalSize!);
      }

      if (localData != null) {
        await database.updateCacheResponse("${AppConstants.clearanceShopProductUri}$sellerId/products?guest_id=1&limit=10&offset=$offset&offer_type=$type", CacheResponseCompanion(
          endPoint: Value("${AppConstants.clearanceShopProductUri}$sellerId/products?guest_id=1&limit=10&offset=$offset&offer_type=$type"),
          header: Value(jsonEncode(apiResponse.response!.headers.map)),
          response: Value(jsonEncode(apiResponse.response!.data)),
        ));
      } else {
        await database.insertCacheResponse(
          CacheResponseCompanion(
            endPoint: Value("${AppConstants.clearanceShopProductUri}$sellerId/products?guest_id=1&limit=10&offset=$offset&offer_type=$type"),
            header: Value(jsonEncode(apiResponse.response!.headers.map)),
            response: Value(jsonEncode(apiResponse.response!.data)),
          ),
        );
      }
    }
    notifyListeners();
  }


  void emptyClearanceProductList() {
    clearanceProductModel = null;
  }


  ProductModel? clearanceSearchProductModel;
  bool isSearchLoading = false;
  bool isSearchActive = false;
  bool isFilterActive = false;
  Future <ApiResponse> getClearanceSearchProduct(String sellerId, int offset, String productId, {
    bool reload = true,
    String search = '',
    String? categoryIds = '[]',
    String? brandIds = '[]',
    String? authorIds = '[]',
    String? publishingIds = '[]',
    String? productType = 'all',
    String? offerType = 'clearance_sale',
    bool fromPaginantion = false
  }) async {

    !fromPaginantion ? isSearchLoading = true : null;
    notifyListeners();

    // if(reload) {
    //   sellerProduct = null;
    // }

    ApiResponse apiResponse = await shopServiceInterface!.getClearanceSearchProduct(
        sellerId, offset.toString(),
        productId, categoryIds : categoryIds,
        brandIds: brandIds, search: search,
        authorIds: authorIds, publishingIds: publishingIds,
        productType: productType,
        offerType: offerType
    );
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      if(offset == 1){
        clearanceSearchProductModel = null;
        clearanceSearchProductModel = ProductModel.fromJson(apiResponse.response!.data);
      }else{
        clearanceSearchProductModel?.products?.addAll(ProductModel.fromJson(apiResponse.response!.data).products!);
        clearanceSearchProductModel?.offset = (ProductModel.fromJson(apiResponse.response!.data).offset!);
        clearanceSearchProductModel?.totalSize = ProductModel.fromJson(apiResponse.response!.data).totalSize;
      }
    } else {
      ApiChecker.checkApi( apiResponse);
    }

    isSearchLoading = false;

    notifyListeners();
    return apiResponse;
  }


  int? _clearanceSaleProductSelectedIndex;
  int? get clearanceSaleProductSelectedIndex => _clearanceSaleProductSelectedIndex;

  void changeSelectedIndex(int selectedIndex) {
    _clearanceSaleProductSelectedIndex = selectedIndex;
    notifyListeners();
  }


  void setSearchText(String? value, {bool isUpdate = true}) {
    _searchText = value;
  }


  void toggleSearchActive(){
    isSearchActive = !isSearchActive;
    notifyListeners();
  }


  void disableSearch({bool isUpdate = true}) {
    isSearchActive = false;
    isSearchLoading = false;
    isFilterActive = false;
    if(isUpdate){
      notifyListeners();
    }
  }


}
