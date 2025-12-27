import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/controllers/address_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/domain/models/address_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/controllers/checkout_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:provider/provider.dart';

class InlineAddressSelectionWidget extends StatefulWidget {
  final bool isBilling;
  
  const InlineAddressSelectionWidget({
    super.key,
    this.isBilling = false,
  });

  @override
  State<InlineAddressSelectionWidget> createState() => _InlineAddressSelectionWidgetState();
}

class _InlineAddressSelectionWidgetState extends State<InlineAddressSelectionWidget> {
  bool _isAddingNew = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AddressController>(
      builder: (context, addressController, _) {
        return Consumer<CheckoutController>(
          builder: (context, checkoutController, _) {
            final selectedIndex = widget.isBilling 
                ? checkoutController.billingAddressIndex 
                : checkoutController.addressIndex;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(width: 18, child: Image.asset(Images.deliveryTo)),
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                        Text(
                          widget.isBilling
                              ? getTranslated('billing_address', context) ?? ''
                              : getTranslated('delivery_to', context) ?? '',
                          style: textMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),

                // Address list or loading
                if (addressController.addressList == null)
                  const Center(child: CircularProgressIndicator())
                else if (addressController.addressList!.isEmpty && !_isAddingNew)
                  _buildEmptyAddressState()
                else
                  ..._buildAddressList(addressController, checkoutController, selectedIndex),

                const SizedBox(height: Dimensions.paddingSizeSmall),

                // Add new address button/form
                _buildAddNewAddressSection(addressController, checkoutController),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyAddressState() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Theme.of(context).hintColor),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Text(
              getTranslated('no_address_found', context) ?? '',
              style: textRegular.copyWith(color: Theme.of(context).hintColor),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAddressList(
    AddressController addressController,
    CheckoutController checkoutController,
    int? selectedIndex,
  ) {
    return List.generate(
      addressController.addressList!.length,
      (index) {
        final address = addressController.addressList![index];
        final isSelected = selectedIndex == index;

        return InkWell(
          onTap: () {
            if (widget.isBilling) {
              checkoutController.setBillingAddressIndex(index);
            } else {
              checkoutController.setAddressIndex(index);
            }
            setState(() {});
          },
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                // Address details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        address.addressType ?? '',
                        style: textBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      _buildAddressInfo(Icons.person, address.contactPersonName ?? ''),
                      _buildAddressInfo(Icons.phone, address.phone ?? ''),
                      _buildAddressInfo(Icons.location_on, address.address ?? ''),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddressInfo(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).hintColor),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Expanded(
            child: Text(
              text,
              style: textRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).hintColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddNewAddressSection(
    AddressController addressController,
    CheckoutController checkoutController,
  ) {
    if (_isAddingNew) {
      return _buildAddNewAddressForm(addressController, checkoutController);
    }

    return InkWell(
      onTap: () => setState(() => _isAddingNew = true),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).primaryColor),
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: Theme.of(context).primaryColor),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Text(
              getTranslated('add_new_address', context) ?? '',
              style: textMedium.copyWith(color: Theme.of(context).primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewAddressForm(
    AddressController addressController,
    CheckoutController checkoutController,
  ) {
    // Simplified inline form - for now just show a message
    // In a complete implementation, this would include all address fields
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                getTranslated('add_new_address', context) ?? '',
                style: textBold.copyWith(fontSize: Dimensions.fontSizeDefault),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _isAddingNew = false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Text(
            getTranslated('add_address_note', context) ?? 
            'Please use the Add New Address button to add a complete address with all required fields.',
            style: textRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _isAddingNew = false),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                ),
              ),
              child: Text(
                getTranslated('close', context) ?? 'Close',
                style: textMedium.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
