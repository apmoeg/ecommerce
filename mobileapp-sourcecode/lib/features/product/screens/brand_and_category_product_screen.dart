import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/paginated_list_view_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/product/controllers/product_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/product_shimmer_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/product_widget.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

class BrandAndCategoryProductScreen extends StatefulWidget {
  final bool isBrand;
  final int? id;
  final String? name;
  final String? image;
  const BrandAndCategoryProductScreen({super.key, required this.isBrand, required this.id, required this.name, this.image});

  @override
  State<BrandAndCategoryProductScreen> createState() => _BrandAndCategoryProductScreenState();
}

class _BrandAndCategoryProductScreenState extends State<BrandAndCategoryProductScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    Provider.of<ProductController>(context, listen: false).initBrandOrCategoryProductList(isBrand: widget.isBrand, id: widget.id, offset: 1, isUpdate: false);
    super.initState();
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: CustomAppBar(title: widget.name),
      body: Consumer<ProductController>(
        builder: (context, productController, child) {
          if(productController.brandOrCategoryProductList == null) return ProductShimmer(isHomePage: false, isEnabled: productController.brandOrCategoryProductList == null,);

          return (productController.brandOrCategoryProductList?.products?.isNotEmpty ?? false) ? PaginatedListView(
            scrollController: _scrollController,
            onPaginate: (offset) async {
             await productController.initBrandOrCategoryProductList(isBrand: widget.isBrand, id: widget.id, offset: offset ?? 1);
            },
            limit: productController.brandOrCategoryProductList?.limit,
            totalSize: productController.brandOrCategoryProductList?.totalSize,
            offset: productController.brandOrCategoryProductList?.offset,
            itemView :  Expanded(
              child: MasonryGridView.count(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall).copyWith(top: Dimensions.paddingSizeExtraSmall),
                crossAxisCount: MediaQuery.of(context).size.width> 480 ? 3 : 2,
                itemCount: productController.brandOrCategoryProductList?.products?.length ?? 0,
                itemBuilder: (BuildContext context, int index) {
                  return ProductWidget(productModel: productController.brandOrCategoryProductList!.products![index]);
                },
              ),
            ),
          ) : productController.brandOrCategoryProductList == null
              ? ProductShimmer(isHomePage: false, isEnabled: productController.brandOrCategoryProductList == null)
              : const NoInternetOrDataScreenWidget(
            isNoInternet: false, icon: Images.noProduct, message: 'no_product_found',
          );
        },
      ),
    );
  }
}