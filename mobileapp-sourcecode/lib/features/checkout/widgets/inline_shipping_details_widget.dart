import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/controllers/checkout_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/create_account_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/widgets/inline_address_selection_widget.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:provider/provider.dart';

class InlineShippingDetailsWidget extends StatefulWidget {
  final bool hasPhysical;
  final bool billingAddress;
  final GlobalKey<FormState> passwordFormKey;

  const InlineShippingDetailsWidget({
    super.key,
    required this.hasPhysical,
    required this.billingAddress,
    required this.passwordFormKey,
  });

  @override
  State<InlineShippingDetailsWidget> createState() => _InlineShippingDetailsWidgetState();
}

class _InlineShippingDetailsWidgetState extends State<InlineShippingDetailsWidget> {
  @override
  Widget build(BuildContext context) {
    bool isGuestMode = !Provider.of<AuthController>(context, listen: false).isLoggedIn();

    return Consumer<CheckoutController>(
      builder: (context, checkoutProvider, _) {
        if (checkoutProvider.sameAsBilling && !widget.hasPhysical) {
          checkoutProvider.setSameAsBilling();
        }

        return Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shipping Address Section
              if (widget.hasPhysical)
                Card(
                  child: Container(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
                      color: Theme.of(context).cardColor,
                    ),
                    child: InlineAddressSelectionWidget(isBilling: false),
                  ),
                ),

              SizedBox(height: widget.hasPhysical ? Dimensions.paddingSizeDefault : 0),

              // Guest Account Creation
              if (isGuestMode && widget.hasPhysical)
                CreateAccountWidget(formKey: widget.passwordFormKey),

              if (isGuestMode) const SizedBox(height: Dimensions.paddingSizeSmall),

              // Same as Billing Checkbox
              if (widget.hasPhysical && widget.billingAddress)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: widget.hasPhysical ? Dimensions.paddingSizeSmall : 0,
                  ),
                  child: InkWell(
                    highlightColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onTap: () => checkoutProvider.setSameAsBilling(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).primaryColor.withOpacity(0.75),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.check,
                              size: 15,
                              color: checkoutProvider.sameAsBilling
                                  ? Theme.of(context).primaryColor.withOpacity(0.75)
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                        Text(
                          getTranslated('same_as_billing_address', context) ?? '',
                          style: textRegular.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Billing Address Section
              if (widget.billingAddress && !checkoutProvider.sameAsBilling)
                Card(
                  child: Container(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
                      color: Theme.of(context).cardColor,
                    ),
                    child: InlineAddressSelectionWidget(isBilling: true),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
