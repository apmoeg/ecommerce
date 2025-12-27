import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/controllers/checkout_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/offline_payment/domain/models/offline_payment_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/domain/models/config_model.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';

class InlinePaymentMethodWidget extends StatefulWidget {
  final bool onlyDigital;

  const InlinePaymentMethodWidget({
    super.key,
    required this.onlyDigital,
  });

  @override
  State<InlinePaymentMethodWidget> createState() => _InlinePaymentMethodWidgetState();
}

class _InlinePaymentMethodWidgetState extends State<InlinePaymentMethodWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<CheckoutController>(
      builder: (context, checkoutController, _) {
        return Consumer<SplashController>(
          builder: (context, splashController, _) {
            final configModel = splashController.configModel;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.payment, size: 18),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Text(
                      getTranslated('payment_method', context) ?? '',
                      style: textMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Text(
                  getTranslated('select_payment_method', context) ?? 'Select your payment method',
                  style: textRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                // Payment method options
                _buildPaymentOptions(checkoutController, configModel),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentOptions(CheckoutController checkoutController, ConfigModel? configModel) {
    return Column(
      children: [
        // Cash on Delivery
        if ((configModel?.cashOnDelivery ?? false) && !widget.onlyDigital)
          _buildPaymentOption(
            title: getTranslated('cash_on_delivery', context) ?? '',
            icon: Images.cod,
            isSelected: checkoutController.isCODChecked,
            onTap: () {
              checkoutController.setOfflineChecked('cod');
              setState(() {});
            },
          ),

        // Wallet Payment
        if (configModel?.walletStatus == 1)
          _buildPaymentOption(
            title: getTranslated('wallet_payment', context) ?? '',
            icon: Images.wallet,
            isSelected: checkoutController.isWalletChecked,
            onTap: () {
              checkoutController.setOfflineChecked('wallet');
              setState(() {});
            },
          ),

        // Offline Payment
        if (configModel?.offlinePayment != null && 
            _hasOfflineMethods(checkoutController.offlinePaymentModel?.offlineMethods))
          _buildPaymentOption(
            title: getTranslated('offline_payment', context) ?? '',
            icon: Images.offlinePayment,
            isSelected: checkoutController.isOfflineChecked,
            onTap: () {
              checkoutController.setOfflineChecked('offline');
              setState(() {});
            },
          ),

        // Digital Payment Methods
        if (configModel?.paymentMethods != null)
          ..._buildDigitalPaymentMethods(checkoutController, configModel!),
      ],
    );
  }

  List<Widget> _buildDigitalPaymentMethods(
    CheckoutController checkoutController,
    ConfigModel configModel,
  ) {
    return List.generate(
      configModel.paymentMethods?.length ?? 0,
      (index) {
        final paymentMethod = configModel.paymentMethods![index];
        final isSelected = checkoutController.paymentMethodIndex == index &&
            !checkoutController.isCODChecked &&
            !checkoutController.isWalletChecked &&
            !checkoutController.isOfflineChecked;

        return _buildPaymentOption(
          title: paymentMethod.additionalDatas?.gatewayTitle ?? '',
          imageUrl:
              '${configModel.paymentMethodImagePath}/${paymentMethod.additionalDatas?.gatewayImage ?? ''}',
          isSelected: isSelected,
          onTap: () {
            checkoutController.setDigitalPaymentMethodName(
              index,
              paymentMethod.additionalDatas?.gatewayTitle ?? '',
            );
            setState(() {});
          },
        );
      },
    );
  }

  Widget _buildPaymentOption({
    required String title,
    String? icon,
    String? imageUrl,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Theme.of(context).cardColor,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        ),
        child: Row(
          children: [
            // Radio button
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).hintColor,
              size: 20,
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            // Payment icon/image
            if (icon != null)
              SizedBox(
                width: 30,
                height: 30,
                child: Image.asset(icon, fit: BoxFit.contain),
              )
            else if (imageUrl != null)
              SizedBox(
                width: 30,
                height: 30,
                child: CustomImageWidget(image: imageUrl, fit: BoxFit.contain),
              ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            // Payment title
            Expanded(
              child: Text(
                title,
                style: textMedium.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasOfflineMethods(List<OfflineMethodModel>? methods) {
    return methods != null && methods.isNotEmpty;
  }
}
