import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/data/local/cache_response.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/brand/domain/models/brand_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/brand/domain/repositories/brand_repository.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';


class BrandController extends ChangeNotifier {
  final BrandRepository? brandRepo;
  BrandController({required this.brandRepo});


  Brand? _brandModel;
  Brand? get brandModel => _brandModel;

  List<BrandModel> _brandList = [];
  List<BrandModel> get brandList => _brandList;
  final List<BrandModel> _originalBrandList = [];

  Future<void> getBrandList(bool reload, {int offset =1}) async {
    var localData =  await database.getCacheResponseById(AppConstants.brandUri);

    if(localData != null && offset == 1) {
      var brandList = jsonDecode(localData.response);

      _brandModel = Brand.fromJson(brandList);
      _brandModel?.brands?.forEach((brand) => _originalBrandList.add(brand));
      _brandList.clear();
      _brandModel?.brands?.forEach((brand) => _brandList.add(brand));
      notifyListeners();
    }

    if(reload ){
      _brandList.clear();
      _originalBrandList.clear();
    }



      ApiResponse apiResponse = await brandRepo!.getBrandList(offset);


      if(apiResponse.response?.statusCode == 200) {
        if(offset ==1  && Brand.fromJson(apiResponse.response!.data).brands != null) {
          _brandList.clear();
          _originalBrandList.clear();

          _brandModel = Brand.fromJson(apiResponse.response!.data);
          apiResponse.response?.data['brands'].forEach((brand) => _originalBrandList.add(BrandModel.fromJson(brand)));
          apiResponse.response!.data['brands'].forEach((brand) => _brandList.add(BrandModel.fromJson(brand)));

          if(localData != null) {
            await database.updateCacheResponse(AppConstants.brandUri, CacheResponseCompanion(
              endPoint: const Value(AppConstants.brandUri),
              header: Value(jsonEncode(apiResponse.response!.headers.map)),
              response: Value(jsonEncode(apiResponse.response!.data)),
            ));
          } else {
            await database.insertCacheResponse(
              CacheResponseCompanion(
                endPoint: const Value(AppConstants.brandUri),
                header: Value(jsonEncode(apiResponse.response!.headers.map)),
                response: Value(jsonEncode(apiResponse.response!.data)),
              ),
            );
          }
        } else if (Brand.fromJson(apiResponse.response?.data).brands != null &&  Brand.fromJson(apiResponse.response?.data).brands!.isNotEmpty) {
          _brandModel = Brand.fromJson(apiResponse.response!.data);
          apiResponse.response?.data['brands'].forEach((brand) => _originalBrandList.add(BrandModel.fromJson(brand)));
          apiResponse.response!.data['brands'].forEach((brand) => _brandList.add(BrandModel.fromJson(brand)));
        }

        notifyListeners();
    }
  }

  Future<void> getSellerWiseBrandList(int sellerId) async {
      ApiResponse apiResponse = await brandRepo!.getSellerWiseBrandList(sellerId);
        _originalBrandList.clear();

        if(apiResponse.response!.data['brands'] != null) {
          apiResponse.response!.data['brands'].forEach((brand) => _originalBrandList.add(BrandModel.fromJson(brand)));
          _brandList.clear();
          apiResponse.response!.data['brands'].forEach((brand) => _brandList.add(BrandModel.fromJson(brand)));
        }

      notifyListeners();
  }

  final List<int> _selectedBrandIds = [];
  List<int> get selectedBrandIds => _selectedBrandIds;


  void checkedToggleBrand(int index){
    _brandList[index].checked = !_brandList[index].checked!;

    if(_brandList[index].checked ?? false) {
      if(!_selectedBrandIds.contains(index)) {
        _selectedBrandIds.add(index);
      }
    }else {
      _selectedBrandIds.remove(index);
    }
    notifyListeners();
  }

  bool isTopBrand = true;
  bool isAZ = false;
  bool isZA = false;

  void sortBrandLis(int value) {
    if (value == 0) {
      _brandList.clear();
      _brandList.addAll(_originalBrandList);
      isTopBrand = true;
      isAZ = false;
      isZA = false;
    } else if (value == 1) {
      _brandList.clear();
      _brandList.addAll(_originalBrandList);
      _brandList.sort((a, b) => a.name!.toLowerCase().compareTo(b.name!.toLowerCase()));
      isTopBrand = false;
      isAZ = true;
      isZA = false;
    } else if (value == 2) {
      _brandList.clear();
      _brandList.addAll(_originalBrandList);
      _brandList.sort((a, b) => a.name!.toLowerCase().compareTo(b.name!.toLowerCase()));
      Iterable iterable = _brandList.reversed;
      _brandList = iterable.toList() as List<BrandModel>;
      isTopBrand = false;
      isAZ = false;
      isZA = true;
    }

    notifyListeners();
  }
}
