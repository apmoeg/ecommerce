@extends('theme-views.layouts.app')

@section('title', translate('checkout').' | '.$web_config['company_name'].' '.translate('ecommerce'))

@push('css_or_js')
    <link rel="stylesheet" href="{{ theme_asset('assets/css/payment.css') }}">
    <script src="https://polyfill.io/v3/polyfill.min.js?version=3.52.1&features=fetch"></script>
    <script src="https://js.stripe.com/v3/"></script>
@endpush

@section('content')
@php($billingInputByCustomer=getWebConfig(name: 'billing_input_by_customer'))
@php($adminFlatShippingEnabled = \App\Utils\Helpers::isAdminFlatShippingEnabled())
    <main class="main-content d-flex flex-column gap-3 py-3 mb-5">
        <div class="container">
            <div class="row g-3">
                <div class="col-12">
                    <h2 class="mb-0">{{translate('checkout')}}</h2>
                    @if($adminFlatShippingEnabled)
                        <div class="alert alert-info d-flex align-items-center gap-2 mt-2">
                            <i class="bi bi-check-circle"></i>
                            <span>{{ translate('Shipping') }}: {{ translate('admin_flat_rate') }} - {{ webCurrencyConverter(amount: \App\Utils\Helpers::getAdminFlatShippingRate()) }}</span>
                        </div>
                    @endif
                </div>
                
                <div class="col-lg-8">
                    @if($physical_product_view)
                        <input type="hidden" id="physical_product" name="physical_product" value="{{ $physical_product_view ? 'yes':'no'}}">
                        
                        {{-- SECTION 1: Shipping Address --}}
                        <div class="card mb-3">
                            <div class="card-header bg-light">
                                <h5 class="mb-0 d-flex align-items-center gap-2">
                                    <i class="bi bi-house"></i> 
                                    {{ translate('1._shipping_address')}}
                                </h5>
                            </div>
                            <div class="card-body">
                                @php($shippingAddresses= \App\Models\ShippingAddress::where(['customer_id'=>auth('customer')->id() ?? session('guest_id'), 'is_guest'=> auth('customer')->check() ? 0 : 1])->get())
                                <form method="post" id="address-form">
                                    @csrf
                                    @if ($shippingAddresses->count() > 0)
                                        <div class="mb-3">
                                            <label class="form-label">{{ translate('saved_addresses')}}</label>
                                            <select class="form-select" id="saved-address-select">
                                                <option value="">{{ translate('add_new_address')}}</option>
                                                @foreach($shippingAddresses as $key => $address)
                                                    <option value="{{$key}}" data-address='{{json_encode($address)}}'>
                                                        {{$address->address_type}} - {{$address->address}}
                                                    </option>
                                                @endforeach
                                            </select>
                                        </div>
                                    @endif

                                    <div class="row g-3">
                                        <div class="col-sm-6">
                                            <label class="form-label">{{ translate('contact_person_name')}} <span class="text-danger">*</span></label>
                                            <input type="text" class="form-control" name="contact_person_name" id="name" required>
                                        </div>
                                        <div class="col-sm-6">
                                            <label class="form-label">{{ translate('phone')}} <span class="text-danger">*</span></label>
                                            <input type="tel" class="form-control" id="phone" name="phone" required>
                                        </div>
                                        @if(!auth('customer')->check())
                                            <div class="col-12">
                                                <label class="form-label">{{ translate('email')}} <span class="text-danger">*</span></label>
                                                <input type="email" class="form-control" name="email" id="email" required>
                                            </div>
                                        @endif
                                        <div class="col-12">
                                            <label class="form-label">{{ translate('address')}}</label>
                                            <textarea class="form-control" name="address" id="address" rows="3" required></textarea>
                                        </div>
                                        <div class="col-sm-6">
                                            <label class="form-label">{{ translate('city')}}</label>
                                            <input type="text" class="form-control" name="city" id="city">
                                        </div>
                                        <div class="col-sm-6">
                                            <label class="form-label">{{ translate('zip_code')}}</label>
                                            <input type="text" class="form-control" name="zip" id="zip">
                                        </div>
                                    </div>
                                    <button type="button" class="btn btn-primary mt-3" id="save-address-btn">
                                        {{ translate('save_and_continue')}}
                                    </button>
                                </form>
                            </div>
                        </div>
                    @endif

                    {{-- SECTION 2: Payment Method --}}
                    <div class="card mb-3" id="payment-section" style="display: none;">
                        <div class="card-header bg-light">
                            <h5 class="mb-0 d-flex align-items-center gap-2">
                                <i class="bi bi-wallet2"></i> 
                                {{ translate('2._payment_method')}}
                            </h5>
                        </div>
                        <div class="card-body">
                            @if($cash_on_delivery && $cash_on_delivery['status'])
                                <div class="form-check mb-3">
                                    <input class="form-check-input" type="radio" name="payment_method" id="cash-on-delivery" value="cash_on_delivery" checked>
                                    <label class="form-check-label d-flex align-items-center gap-2" for="cash-on-delivery">
                                        <i class="bi bi-cash"></i>
                                        {{ translate('cash_on_delivery')}}
                                    </label>
                                </div>
                            @endif

                            @if(auth('customer')->check() && $wallet_status == 1)
                                <div class="form-check mb-3">
                                    <input class="form-check-input" type="radio" name="payment_method" id="wallet-payment" value="wallet">
                                    <label class="form-check-label d-flex align-items-center gap-2" for="wallet-payment">
                                        <i class="bi bi-wallet"></i>
                                        {{ translate('wallet_payment')}}
                                    </label>
                                </div>
                            @endif

                            @if($digital_payment && $digital_payment['status'] == 1)
                                <div class="form-check mb-3">
                                    <input class="form-check-input" type="radio" name="payment_method" id="digital-payment" value="digital_payment">
                                    <label class="form-check-label d-flex align-items-center gap-2" for="digital-payment">
                                        <i class="bi bi-credit-card"></i>
                                        {{ translate('digital_payment')}}
                                    </label>
                                </div>
                            @endif

                            <div class="mt-3">
                                <button type="button" class="btn btn-primary" id="continue-to-review-btn">
                                    {{ translate('continue_to_review')}}
                                </button>
                            </div>
                        </div>
                    </div>

                    {{-- SECTION 3: Order Review --}}
                    <div class="card mb-3" id="review-section" style="display: none;">
                        <div class="card-header bg-light">
                            <h5 class="mb-0 d-flex align-items-center gap-2">
                                <i class="bi bi-check-circle"></i> 
                                {{ translate('3._order_review')}}
                            </h5>
                        </div>
                        <div class="card-body">
                            <div class="alert alert-success">
                                <i class="bi bi-info-circle"></i>
                                {{ translate('Please_review_your_order_and_place_it')}}
                            </div>
                            
                            @if($adminFlatShippingEnabled)
                                <div class="mb-3 p-3 bg-light rounded">
                                    <div class="d-flex justify-content-between">
                                        <span class="fw-bold">{{ translate('shipping')}}:</span>
                                        <span>{{ translate('admin_flat_rate') }} - {{ webCurrencyConverter(amount: \App\Utils\Helpers::getAdminFlatShippingRate()) }}</span>
                                    </div>
                                    <small class="text-muted">{{ translate('Flat_shipping_rate_applied_to_entire_order')}}</small>
                                </div>
                            @endif

                            <form method="get" id="checkout-form" action="{{route('checkout-complete')}}">
                                <input type="hidden" name="payment_method" id="final-payment-method">
                                <button type="submit" class="btn btn-primary w-100">
                                    <i class="bi bi-bag-check"></i> {{ translate('place_order')}}
                                </button>
                            </form>
                        </div>
                    </div>
                </div>

                {{-- Order Summary Sidebar --}}
                <div class="col-lg-4">
                    <div class="card sticky-top" style="top: 100px;">
                        <div class="card-header bg-light">
                            <h5 class="mb-0">{{ translate('order_summary')}}</h5>
                        </div>
                        <div class="card-body">
                            @php($cart=\App\Utils\CartManager::getCartListQuery(type: 'checked'))
                            @php($subTotal=0)
                            @php($totalTax=0)
                            @php($totalShippingCost=0)
                            @php($totalDiscountOnProduct=0)
                            @php($getShippingCost=\App\Utils\CartManager::get_shipping_cost(type: 'checked'))
                            
                            @if($cart->count() > 0)
                                @foreach($cart as $cartItem)
                                    @php($subTotal+=$cartItem['price']*$cartItem['quantity'])
                                    @php($totalTax+=$cartItem['tax_model']=='exclude' ? ($cartItem['tax']*$cartItem['quantity']):0)
                                    @php($totalDiscountOnProduct+=$cartItem['discount']*$cartItem['quantity'])
                                @endforeach
                                @php($totalShippingCost=$getShippingCost)
                            @endif

                            <div class="d-flex justify-content-between mb-2">
                                <span>{{translate('subtotal')}}</span>
                                <span>{{ webCurrencyConverter(amount: $subTotal) }}</span>
                            </div>
                            <div class="d-flex justify-content-between mb-2">
                                <span>{{translate('tax')}}</span>
                                <span>{{ webCurrencyConverter(amount: $totalTax) }}</span>
                            </div>
                            <div class="d-flex justify-content-between mb-2">
                                <span>
                                    @if($adminFlatShippingEnabled)
                                        {{translate('shipping')}} ({{ translate('admin_flat_rate') }})
                                    @else
                                        {{translate('shipping')}}
                                    @endif
                                </span>
                                <span>{{ webCurrencyConverter(amount: $totalShippingCost) }}</span>
                            </div>
                            @if($totalDiscountOnProduct > 0)
                                <div class="d-flex justify-content-between mb-2">
                                    <span>{{translate('discount')}}</span>
                                    <span>- {{ webCurrencyConverter(amount: $totalDiscountOnProduct) }}</span>
                                </div>
                            @endif
                            <hr>
                            <div class="d-flex justify-content-between fw-bold">
                                <span>{{translate('total')}}</span>
                                <span>{{ webCurrencyConverter(amount: $subTotal+$totalTax+$totalShippingCost-$totalDiscountOnProduct) }}</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </main>
@endsection

@push('script')
<script>
    "use strict";
    $(document).ready(function() {
        // Saved address selection
        $('#saved-address-select').change(function() {
            let addressData = $(this).find(':selected').data('address');
            if(addressData) {
                $('#name').val(addressData.contact_person_name);
                $('#phone').val(addressData.phone);
                $('#address').val(addressData.address);
                $('#city').val(addressData.city);
                $('#zip').val(addressData.zip);
            } else {
                $('#address-form')[0].reset();
            }
        });

        // Save address and show payment section
        $('#save-address-btn').click(function() {
            if($('#address-form')[0].checkValidity()) {
                $.ajax({
                    url: '{{ route("customer.choose-shipping-address") }}',
                    method: 'POST',
                    data: $('#address-form').serialize(),
                    success: function(response) {
                        if(response.status == 1) {
                            $('#payment-section').slideDown();
                            $('html, body').animate({
                                scrollTop: $("#payment-section").offset().top - 100
                            }, 500);
                        }
                    }
                });
            } else {
                $('#address-form')[0].reportValidity();
            }
        });

        // Continue to review
        $('#continue-to-review-btn').click(function() {
            let paymentMethod = $('input[name="payment_method"]:checked').val();
            if(paymentMethod) {
                $('#final-payment-method').val(paymentMethod);
                $('#review-section').slideDown();
                $('html, body').animate({
                    scrollTop: $("#review-section").offset().top - 100
                }, 500);
            } else {
                alert('{{ translate("please_select_a_payment_method") }}');
            }
        });
    });
</script>
@endpush
