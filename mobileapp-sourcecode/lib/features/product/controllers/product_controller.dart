import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/data/local/cache_response.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/category/domain/models/find_what_you_need.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/home_category_product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/most_demanded_product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/models/product_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/domain/services/product_service_interface.dart';
import 'package:flutter_sixvalley_ecommerce/helper/api_checker.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/enums/product_type.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class ProductController extends ChangeNotifier {
  final ProductServiceInterface? productServiceInterface;
  ProductController({required this.productServiceInterface});

  List<Product>? _latestProductList = [];
  List<Product>? _lProductList;
  List<Product>? get lProductList=> _lProductList;
  List<Product>? _featuredProductList;



  ProductType _productType = ProductType.newArrival;
  String? _title = '${getTranslated('best_selling', Get.context!)}';

  bool _filterIsLoading = false;
  bool _filterFirstLoading = true;

  bool _isLoading = false;
  bool _isFeaturedLoading = false;
  bool get isFeaturedLoading => _isFeaturedLoading;
  bool _firstFeaturedLoading = true;
  bool _firstLoading = true;
  int? _latestPageSize = 1;
  int _lOffset = 1;
  int? _lPageSize;
  int? get lPageSize=> _lPageSize;
  int? _featuredPageSize;
  int _lOffsetFeatured = 1;


  ProductType get productType => _productType;
  String? get title => _title;
  int get lOffset => _lOffset;
  int get lOffsetFeatured => _lOffsetFeatured;


  List<int> _offsetList = [];
  List<String> _lOffsetList = [];
  List<String> get lOffsetList=>_lOffsetList;
  List<String> _featuredOffsetList = [];

  List<Product>? get latestProductList => _latestProductList;
  List<Product>? get featuredProductList => _featuredProductList;

  Product? _recommendedProduct;
  Product? get recommendedProduct=> _recommendedProduct;

  bool get filterIsLoading => _filterIsLoading;
  bool get filterFirstLoading => _filterFirstLoading;
  bool get isLoading => _isLoading;
  bool get firstFeaturedLoading => _firstFeaturedLoading;
  bool get firstLoading => _firstLoading;
  int? get latestPageSize => _latestPageSize;
  int? get featuredPageSize => _featuredPageSize;

  ProductModel? _discountedProductModel;
  ProductModel? get discountedProductModel => _discountedProductModel;


  bool filterApply = false;

  String? _searchText;
  String? get searchText => _searchText;



  void isFilterApply (bool apply, {bool reload = false}){
    filterApply = apply;
    if(reload){
      notifyListeners();
    }
  }


  Future<void> getLatestProductList(int offset, {bool reload = false}) async {

    String ? endUrl;

    if(_productType == ProductType.bestSelling) {
      endUrl = AppConstants.bestSellingProductUri;
    }
    else if(_productType == ProductType.newArrival){
      endUrl = AppConstants.newArrivalProductUri;
    }
    else if(_productType == ProductType.topProduct){
      endUrl = AppConstants.topProductUri;
    }else if(_productType == ProductType.discountedProduct){
      endUrl = AppConstants.discountedProductUri;
    }



    var localData =  await database.getCacheResponseById(endUrl ?? '');


    if(localData != null && offset ==1 && ProductModel.fromJson(jsonDecode(localData.response)).products != null) {
      _latestProductList = [];
      _latestProductList!.addAll(ProductModel.fromJson(jsonDecode(localData.response)).products!);
      _latestPageSize = ProductModel.fromJson(jsonDecode(localData.response)).totalSize;
      _filterFirstLoading = false;
      // _filterIsLoading = false;
      notifyListeners();
    }


    if(reload || offset == 1) {
      _offsetList = [];
      if(localData == null) {
        _latestProductList = null;
      }
    }

    _lOffset = offset;
    if(!_offsetList.contains(offset)) {
      _offsetList.add(offset);
      ApiResponse apiResponse = await productServiceInterface!.getFilteredProductList(Get.context!, offset.toString(), _productType, title);

      if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
        if(offset==1) {
          _latestProductList = [];
        }
          if(ProductModel.fromJson(apiResponse.response!.data).products != null){
            _latestProductList!.addAll(ProductModel.fromJson(apiResponse.response!.data).products!);
            _latestPageSize = ProductModel.fromJson(apiResponse.response!.data).totalSize;

            try{
              if(localData != null && offset ==1 ) {
                await database.updateCacheResponse(endUrl ?? '', CacheResponseCompanion(
                  endPoint: Value(endUrl ?? ''),
                  header: Value(jsonEncode(apiResponse.response!.headers.map)),
                  response: Value(jsonEncode(apiResponse.response!.data)),
                ));
              } else {
                await database.insertCacheResponse(
                  CacheResponseCompanion(
                    endPoint: Value(endUrl ?? ''),
                    header: Value(jsonEncode(apiResponse.response!.headers.map)),
                    response: Value(jsonEncode(apiResponse.response!.data)),
                  ),
                );
              }
            } catch(e) {
              debugPrint("==ProductException==>>$e");
            }
          }

          _filterFirstLoading = false;
          _filterIsLoading = false;
          _filterIsLoading = false;
          removeFirstLoading();
      } else {

        if(reload || offset == 1) {
          _latestProductList = [];
        }
        ApiChecker.checkApi( apiResponse);
      }

      notifyListeners();
    }else {
      if(_filterIsLoading) {
        _filterIsLoading = false;
        notifyListeners();
      }
    }

  }



  //latest product
  Future<void> getLProductList(String offset, {bool reload = false}) async {
    var localData =  await database.getCacheResponseById(AppConstants.latestProductUri);

    if(localData != null) {
      _lProductList = [];
      _lProductList!.addAll(ProductModel.fromJson(jsonDecode(localData.response)).products!);
      _lPageSize = ProductModel.fromJson(jsonDecode(localData.response)).totalSize;

      notifyListeners();
    }


    if(reload) {
      _lOffsetList = [];
      _lProductList = [];
    }
    if(!_lOffsetList.contains(offset)) {
      _lOffsetList.add(offset);
      ApiResponse apiResponse = await productServiceInterface!.getLatestProductList(offset);
      if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
        _lProductList = [];
        _lProductList?.addAll(ProductModel.fromJson(apiResponse.response!.data).products??[]);
        _lPageSize = ProductModel.fromJson(apiResponse.response!.data).totalSize;
        _firstLoading = false;
        _isLoading = false;


        if(localData != null) {
          await database.updateCacheResponse(AppConstants.latestProductUri, CacheResponseCompanion(
            endPoint: const Value(AppConstants.latestProductUri),
            header: Value(jsonEncode(apiResponse.response!.headers.map)),
            response: Value(jsonEncode(apiResponse.response!.data)),
          ));
        } else {
          await database.insertCacheResponse(
            CacheResponseCompanion(
              endPoint: const Value(AppConstants.latestProductUri),
              header: Value(jsonEncode(apiResponse.response!.headers.map)),
              response: Value(jsonEncode(apiResponse.response!.data)),
            ),
          );
        }
      } else {
        ApiChecker.checkApi( apiResponse);
      }


      notifyListeners();
    }else {
      if(_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }

  }


  List<ProductTypeModel> productTypeList = [
    ProductTypeModel('new_arrival', ProductType.newArrival),
    ProductTypeModel('top_product', ProductType.topProduct),
    ProductTypeModel('best_selling', ProductType.bestSelling),
    ProductTypeModel('discounted_product', ProductType.discountedProduct),
  ];

  
int selectedProductTypeIndex = 0;
 void changeTypeOfProduct(ProductType type, String? title, {int index = 0}){
    _productType = type;
    _title = title;
    _latestProductList = null;
    _latestPageSize = 1;
    _filterFirstLoading = true;
    _filterIsLoading = true;
    selectedProductTypeIndex = index;
    getLatestProductList(1, reload: true);
    notifyListeners();
 }

  void showBottomLoader() {
    _isLoading = true;
    _filterIsLoading = true;
    notifyListeners();
  }

  void removeFirstLoading() {
    _firstLoading = true;
    notifyListeners();
  }


  TextEditingController sellerProductSearch = TextEditingController();
  void clearSearchField( String id){
    sellerProductSearch.clear();
    notifyListeners();
  }




  ProductModel? _brandOrCategoryProductList;

  ProductModel? get brandOrCategoryProductList => _brandOrCategoryProductList;

  Future<void> initBrandOrCategoryProductList({required bool isBrand, required int? id, required int offset, bool isUpdate = true}) async {
    if(offset == 1) {
      _brandOrCategoryProductList = null;
    }
    if(isUpdate) {
      notifyListeners();
    }

    ApiResponse apiResponse = await productServiceInterface!.getBrandOrCategoryProductList(isBrand: isBrand, id: id!, offset: offset);

    if (apiResponse.response?.statusCode == 200) {
      if(offset == 1){
        _brandOrCategoryProductList = ProductModel.fromJson(apiResponse.response?.data);

      } else {
        _brandOrCategoryProductList?.products?.addAll(ProductModel.fromJson(apiResponse.response?.data).products ?? []);
        _brandOrCategoryProductList?.offset = ProductModel.fromJson(apiResponse.response?.data).offset;
        _brandOrCategoryProductList?.totalSize = ProductModel.fromJson(apiResponse.response?.data).totalSize;

      }
    } else {
      ApiChecker.checkApi( apiResponse);

    }

    notifyListeners();
  }


  List<Product>? _relatedProductList;
  List<Product>? get relatedProductList => _relatedProductList;

  void initRelatedProductList(String id, BuildContext context) async {
    ApiResponse apiResponse = await productServiceInterface!.getRelatedProductList(id);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _relatedProductList = [];
      apiResponse.response!.data.forEach((product) => _relatedProductList!.add(Product.fromJson(product)));
    } else {
      ApiChecker.checkApi( apiResponse);
    }
    notifyListeners();
  }


  List<Product>? _moreProductList;
  List<Product>? get moreProductList => _moreProductList;

  void getMoreProductList(String id) async {
    ApiResponse apiResponse = await productServiceInterface!.getRelatedProductList(id);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      _relatedProductList = [];
      apiResponse.response!.data.forEach((product) => _relatedProductList!.add(Product.fromJson(product)));
    } else {
      ApiChecker.checkApi( apiResponse);
    }
    notifyListeners();
  }

  void removePrevRelatedProduct() {
    _relatedProductList = null;
  }


  int featuredIndex = 0;
  void setFeaturedIndex(int index){
    featuredIndex = index;
    notifyListeners();
  }



  Future<void> getFeaturedProductList(String offset, {bool reload = false}) async {

    var localData =  await database.getCacheResponseById(AppConstants.featuredProductUri);


    if(localData != null) {
      _featuredOffsetList = [];
      _featuredProductList = [];

      _featuredProductList?.addAll(ProductModel.fromJson(jsonDecode(localData.response)).products!);
      _featuredPageSize = ProductModel.fromJson(jsonDecode(localData.response)).totalSize;

      notifyListeners();
    }


    if(reload) {
      _featuredOffsetList = [];
      _featuredProductList = [];
    }
    if(!_featuredOffsetList.contains(offset)) {
      _featuredOffsetList.add(offset);
      _lOffsetFeatured = int.parse(offset);
      ApiResponse apiResponse = await productServiceInterface!.getFeaturedProductList(offset);
      if (apiResponse.response != null  && apiResponse.response!.statusCode == 200) {
        if (offset == '1') {
          _featuredProductList = [];
          if(apiResponse.response!.data['products'] != null) {
            _featuredProductList?.addAll(ProductModel.fromJson(apiResponse.response!.data).products!);
            _featuredPageSize = ProductModel.fromJson(apiResponse.response!.data).totalSize;
            if(localData != null) {
              await database.updateCacheResponse(AppConstants.featuredProductUri, CacheResponseCompanion(
                endPoint: const Value(AppConstants.featuredProductUri),
                header: Value(jsonEncode(apiResponse.response!.headers.map)),
                response: Value(jsonEncode(apiResponse.response!.data)),
              ));
            } else {
              await database.insertCacheResponse(
                CacheResponseCompanion(
                  endPoint: const Value(AppConstants.featuredProductUri),
                  header: Value(jsonEncode(apiResponse.response!.headers.map)),
                  response: Value(jsonEncode(apiResponse.response!.data)),
                ),
              );
            }
          }
          _firstFeaturedLoading = false;
        } else {
          _featuredPageSize = ProductModel.fromJson(apiResponse.response!.data).totalSize;
          _featuredProductList?.addAll(ProductModel.fromJson(apiResponse.response!.data).products!);
        }


        _isFeaturedLoading = false;
        _filterIsLoading = false;
      } else {
        ApiChecker.checkApi( apiResponse);
      }

      notifyListeners();
    }else {
      if(_isFeaturedLoading) {
        _isFeaturedLoading = false;
        notifyListeners();
      }
    }
  }


  bool recommendedProductLoading = false;
  Future<void> getRecommendedProduct() async {

    var localData =  await database.getCacheResponseById(AppConstants.dealOfTheDay);

    if(localData != null) {
      _recommendedProduct = Product.fromJson(jsonDecode(localData.response));
      notifyListeners();
    }


    ApiResponse apiResponse = await productServiceInterface!.getRecommendedProduct();
      if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
        _recommendedProduct = Product.fromJson(apiResponse.response!.data);

        if(localData != null) {
          await database.updateCacheResponse(AppConstants.dealOfTheDay, CacheResponseCompanion(
            endPoint: const Value(AppConstants.dealOfTheDay),
            header: Value(jsonEncode(apiResponse.response!.headers.map)),
            response: Value(jsonEncode(apiResponse.response!.data)),
          ));
        } else {
          await database.insertCacheResponse(
            CacheResponseCompanion(
              endPoint: const Value(AppConstants.dealOfTheDay),
              header: Value(jsonEncode(apiResponse.response!.headers.map)),
              response: Value(jsonEncode(apiResponse.response!.data)),
            ),
          );
        }
      }
      notifyListeners();
  }


  final List<HomeCategoryProduct> _homeCategoryProductList = [];
  List<HomeCategoryProduct> get homeCategoryProductList => _homeCategoryProductList;

  Future<void> getHomeCategoryProductList(bool reload) async {

    if(_homeCategoryProductList.isEmpty || reload) {
      var localData =  await database.getCacheResponseById(AppConstants.homeCategoryProductUri);

      if(localData != null) {
        var homeCategoryProductList = jsonDecode(localData.response);
        homeCategoryProductList.forEach((homeCategory) => _homeCategoryProductList.add(HomeCategoryProduct.fromJson(homeCategory)));
        notifyListeners();
      }

      ApiResponse apiResponse = await productServiceInterface!.getHomeCategoryProductList();
      if (apiResponse.response != null  && apiResponse.response!.statusCode == 200) {
        if(apiResponse.response!.data.toString() != '{}'){
          _homeCategoryProductList.clear();
          apiResponse.response!.data.forEach((homeCategoryProduct) =>
              _homeCategoryProductList.add(HomeCategoryProduct.fromJson(homeCategoryProduct)));
        }

        if(localData != null) {
          await database.updateCacheResponse(AppConstants.homeCategoryProductUri, CacheResponseCompanion(
            endPoint: const Value(AppConstants.homeCategoryProductUri),
            header: Value(jsonEncode(apiResponse.response!.headers.map)),
            response: Value(jsonEncode(apiResponse.response!.data)),
          ));
        } else {
          await database.insertCacheResponse(
            CacheResponseCompanion(
              endPoint: const Value(AppConstants.homeCategoryProductUri),
              header: Value(jsonEncode(apiResponse.response!.headers.map)),
              response: Value(jsonEncode(apiResponse.response!.data)),
            ),
          );
        }

      } else {
        ApiChecker.checkApi( apiResponse);
      }
      notifyListeners();
    }

  }

  MostDemandedProductModel? mostDemandedProductModel;
  Future<void> getMostDemandedProduct() async {

    var localData =  await database.getCacheResponseById(AppConstants.mostDemandedProduct);

    if(localData != null) {
      mostDemandedProductModel = MostDemandedProductModel.fromJson(jsonDecode(localData.response));
      notifyListeners();
    }

    ApiResponse apiResponse = await productServiceInterface!.getMostDemandedProduct();
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      if(apiResponse.response?.data != null && apiResponse.response?.data.isNotEmpty && apiResponse.response?.data != '[]'){
        mostDemandedProductModel = MostDemandedProductModel.fromJson(apiResponse.response!.data);

        if(localData != null) {
          await database.updateCacheResponse(AppConstants.mostDemandedProduct, CacheResponseCompanion(
            endPoint: const Value(AppConstants.mostDemandedProduct),
            header: Value(jsonEncode(apiResponse.response!.headers.map)),
            response: Value(jsonEncode(apiResponse.response!.data)),
          ));
        } else {
          await database.insertCacheResponse(
            CacheResponseCompanion(
              endPoint: const Value(AppConstants.mostDemandedProduct),
              header: Value(jsonEncode(apiResponse.response!.headers.map)),
              response: Value(jsonEncode(apiResponse.response!.data)),
            ),
          );
        }

      }

    } else {
      ApiChecker.checkApi( apiResponse);
    }
    notifyListeners();
  }

  FindWhatYouNeedModel? findWhatYouNeedModel;
  Future<void> findWhatYouNeed() async {
    var localData =  await database.getCacheResponseById(AppConstants.findWhatYouNeed);

    if(localData != null) {
      findWhatYouNeedModel = FindWhatYouNeedModel.fromJson(jsonDecode(localData.response));
      notifyListeners();
    }


    ApiResponse apiResponse = await productServiceInterface!.getFindWhatYouNeed();
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      findWhatYouNeedModel = FindWhatYouNeedModel.fromJson(apiResponse.response?.data);

      if(localData != null) {
        await database.updateCacheResponse(AppConstants.findWhatYouNeed, CacheResponseCompanion(
          endPoint: const Value(AppConstants.findWhatYouNeed),
          header: Value(jsonEncode(apiResponse.response!.headers.map)),
          response: Value(jsonEncode(apiResponse.response!.data)),
        ));
      } else {
        await database.insertCacheResponse(
          CacheResponseCompanion(
            endPoint: const Value(AppConstants.findWhatYouNeed),
            header: Value(jsonEncode(apiResponse.response!.headers.map)),
            response: Value(jsonEncode(apiResponse.response!.data)),
          ),
        );
      }

    } else {
      ApiChecker.checkApi( apiResponse);
    }
    notifyListeners();
  }

  List<Product>? justForYouProduct;
  Future<void> getJustForYouProduct() async {
    var localData =  await database.getCacheResponseById(AppConstants.justForYou);

    if(localData != null) {
      final data = jsonDecode(localData.response);

      data.forEach((justForYou)=> justForYouProduct?.add(Product.fromJson(justForYou)));
      notifyListeners();
    }

    justForYouProduct = [];
    ApiResponse apiResponse = await productServiceInterface!.getJustForYouProductList();
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
    apiResponse.response?.data.forEach((justForYou)=> justForYouProduct?.add(Product.fromJson(justForYou)));

    if(localData != null) {
      await database.updateCacheResponse(AppConstants.justForYou, CacheResponseCompanion(
        endPoint: const Value(AppConstants.justForYou),
        header: Value(jsonEncode(apiResponse.response!.headers.map)),
        response: Value(jsonEncode(apiResponse.response!.data)),
      ));
    } else {
      await database.insertCacheResponse(
        CacheResponseCompanion(
          endPoint: const Value(AppConstants.justForYou),
          header: Value(jsonEncode(apiResponse.response!.headers.map)),
          response: Value(jsonEncode(apiResponse.response!.data)),
        ),
      );
    }

    }
    notifyListeners();
  }

  ProductModel? mostSearchingProduct;
  Future<void> getMostSearchingProduct(int offset, {bool reload = false}) async {

    var localData =  await database.getCacheResponseById(AppConstants.mostSearching);

    if(localData != null) {
      mostSearchingProduct = ProductModel.fromJson(jsonDecode(localData.response));
      notifyListeners();
    }


    ApiResponse apiResponse = await productServiceInterface!.getMostSearchingProductList(offset);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      if(apiResponse.response?.data['products'] != null && apiResponse.response?.data['products'] != 'null'){
        if(offset == 1) {
          mostSearchingProduct = ProductModel.fromJson(apiResponse.response?.data);

          if(localData != null) {
            await database.updateCacheResponse(AppConstants.mostSearching, CacheResponseCompanion(
              endPoint: const Value(AppConstants.mostSearching),
              header: Value(jsonEncode(apiResponse.response!.headers.map)),
              response: Value(jsonEncode(apiResponse.response!.data)),
            ));
          } else {
            await database.insertCacheResponse(
              CacheResponseCompanion(
                endPoint: const Value(AppConstants.mostSearching),
                header: Value(jsonEncode(apiResponse.response!.headers.map)),
                response: Value(jsonEncode(apiResponse.response!.data)),
              ),
            );
          }


        }else {
          mostSearchingProduct!.products!.addAll(ProductModel.fromJson(apiResponse.response?.data).products!);
          mostSearchingProduct!.offset = ProductModel.fromJson(apiResponse.response?.data).offset;
          mostSearchingProduct!.totalSize = ProductModel.fromJson(apiResponse.response?.data).totalSize;
        }
      }


    } else {
      ApiChecker.checkApi( apiResponse);
    }
    notifyListeners();


  }

  int currentJustForYouIndex = 0;
  void setCurrentJustForYourIndex(int index){
    currentJustForYouIndex = index;
    notifyListeners();
  }

  Future<void> getDiscountedProductList(int offset, bool reload, { bool isUpdate = true}) async {

    if(reload) {
      _discountedProductModel = null;

      if(isUpdate) {
        notifyListeners();
      }
    }

    ApiResponse apiResponse = await productServiceInterface!.getFilteredProductList(Get.context!, offset.toString(), ProductType.discountedProduct, title);

    if (apiResponse.response?.data != null && apiResponse.response?.statusCode == 200) {
      if(offset == 1){
        _discountedProductModel = ProductModel.fromJson(apiResponse.response?.data);
      } else {
        _discountedProductModel?.totalSize = ProductModel.fromJson(apiResponse.response?.data).totalSize;
        _discountedProductModel?.offset = ProductModel.fromJson(apiResponse.response?.data).offset;
        _discountedProductModel?.products?.addAll(ProductModel.fromJson(apiResponse.response?.data).products ?? []);
      }

      notifyListeners();

    } else {
      ApiChecker.checkApi(apiResponse);

    }

  }


  ProductModel? clearanceProductModel;
  Future<void> getClearanceAllProductList( String offset, {bool reload = false}) async {

    var localData =  await database.getCacheResponseById(AppConstants.clearanceAllProductUri);

    if(localData != null) {
      clearanceProductModel = ProductModel.fromJson(jsonDecode(localData.response));
      notifyListeners();
    }

    ApiResponse apiResponse = await productServiceInterface!.getClearanceAllProductList(offset);

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
        await database.updateCacheResponse(AppConstants.clearanceAllProductUri, CacheResponseCompanion(
          endPoint: const Value(AppConstants.clearanceAllProductUri),
          header: Value(jsonEncode(apiResponse.response!.headers.map)),
          response: Value(jsonEncode(apiResponse.response!.data)),
        ));
      } else {
        await database.insertCacheResponse(
          CacheResponseCompanion(
            endPoint: const Value(AppConstants.clearanceAllProductUri),
            header: Value(jsonEncode(apiResponse.response!.headers.map)),
            response: Value(jsonEncode(apiResponse.response!.data)),
          ),
        );
      }
    }
    notifyListeners();
  }


  ProductModel? clearanceSearchProductModel;
  bool isSearchLoading = false;
  bool isSearchActive = false;
  bool isFilterActive = false;
  Future <ApiResponse> getClearanceSearchProduct({required String query, String? categoryIds, String? brandIds,  String? authorIds, String? publishingIds, String? sort, String? priceMin, String? priceMax, required int offset, String? productType, String offerType = 'clearance_sale', bool fromPaginantion = false, isNotify = true}) async {

    if(!fromPaginantion && isNotify){
      isSearchLoading = true;
      notifyListeners();
    }


    // if(reload) {
    //   sellerProduct = null;
    // }

    ApiResponse apiResponse = await productServiceInterface!.getClearanceSearchProducts(query, categoryIds, brandIds, authorIds, publishingIds, sort, priceMin, priceMax, offset, productType, offerType);
    if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
      if(offset == 1){
        // clearanceSearchProductModel = null;
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


  void setSearchText(String? value, {bool isUpdate = true}) {
    _searchText = value;
  }


  void toggleSearchActive(){
    isSearchActive = !isSearchActive;
    notifyListeners();
  }


  void disableSearch({bool isUpdate = true}) {
    clearanceSearchProductModel = null;
    isSearchActive = false;
    isSearchLoading = false;
    isFilterActive = false;
    if(isUpdate){
      notifyListeners();
    }
  }


}

class ProductTypeModel{
  String? title;
  ProductType productType;

  ProductTypeModel(this.title, this.productType);
}

