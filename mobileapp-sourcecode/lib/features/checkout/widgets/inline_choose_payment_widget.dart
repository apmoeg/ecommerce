import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/inline_payment_method_widget.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';

class InlineChoosePaymentWidget extends StatelessWidget {
  final bool onlyDigital;

  const InlineChoosePaymentWidget({
    super.key,
    required this.onlyDigital,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
          color: Theme.of(context).cardColor,
        ),
        child: InlinePaymentMethodWidget(onlyDigital: onlyDigital),
      ),
    );
  }
}
