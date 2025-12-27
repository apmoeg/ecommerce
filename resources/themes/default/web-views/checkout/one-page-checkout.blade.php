@extends('layouts.front-end.app')

@section('title',translate('checkout'))

@push('css_or_js')
    <link rel="stylesheet" href="{{ theme_asset(path: 'public/assets/front-end/css/bootstrap-select.min.css') }}">
    <link rel="stylesheet" href="{{ theme_asset(path: 'public/assets/front-end/plugin/intl-tel-input/css/intlTelInput.css') }}">
    <link rel="stylesheet" href="{{ theme_asset(path: 'public/assets/front-end/css/payment.css') }}">
    <script src="https://polyfill.io/v3/polyfill.min.js?version=3.52.1&features=fetch"></script>
    <script src="https://js.stripe.com/v3/"></script>
@endpush

@section('content')
@php($billingInputByCustomer=getWebConfig(name: 'billing_input_by_customer'))
@php($adminFlatShippingEnabled = \App\Utils\Helpers::isAdminFlatShippingEnabled())
    <div class="container py-4 rtl __inline-56 px-0 px-md-3 text-align-direction">
        <div class="row mx-max-md-0">
            <div class="col-md-12 mb-3">
                <h3 class="font-weight-bold text-center text-lg-left">{{translate('checkout')}}</h3>
                @if($adminFlatShippingEnabled)
                    <div class="alert alert-info d-flex align-items-center gap-2 mt-2">
                        <i class="tio-checkmark-circle-outlined"></i>
                        <span>{{ translate('Shipping') }}: {{ translate('admin_flat_rate') }} - {{ webCurrencyConverter(amount: \App\Utils\Helpers::getAdminFlatShippingRate()) }}</span>
                    </div>
                @endif
            </div>
            
            <section class="col-lg-8 px-max-md-0">
                <div class="checkout_details">
                    @php($defaultLocation = getWebConfig(name: 'default_location'))

                    @if($physical_product_view)
                        <input type="hidden" id="physical_product" name="physical_product" value="{{ $physical_product_view ? 'yes':'no'}}">
                        
                        {{-- SECTION 1: Shipping Address --}}
                        <div class="card __card mb-3">
                            <div class="card-header bg-light">
                                <h5 class="mb-0">
                                    <i class="tio-home-outlined"></i> 
                                    {{ translate('1._shipping_address')}}
                                </h5>
                            </div>
                            <div class="card-body">
                                @php($shippingAddresses= \App\Models\ShippingAddress::where(['customer_id'=>auth('customer')->id() ?? session('guest_id'), 'is_guest'=> auth('customer')->check() ? 0 : 1])->get())
                                <form method="post" id="address-form">
                                    @if ($shippingAddresses->count() > 0)
                                        <div class="mb-3">
                                            <label class="form-label">{{ translate('saved_addresses')}}</label>
                                            <select class="form-control" id="saved-address-select">
                                                <option value="">{{ translate('add_new_address')}}</option>
                                                @foreach($shippingAddresses as $key => $address)
                                                    <option value="{{$key}}" data-address='{{json_encode($address)}}'>
                                                        {{$address->address_type}} - {{$address->address}}
                                                    </option>
                                                @endforeach
                                            </select>
                                        </div>
                                    @endif

                                    <div class="row">
                                        <div class="col-sm-6">
                                            <div class="form-group">
                                                <label>{{ translate('contact_person_name')}} <span class="text-danger">*</span></label>
                                                <input type="text" class="form-control" name="contact_person_name" id="name" required>
                                            </div>
                                        </div>
                                        <div class="col-sm-6">
                                            <div class="form-group">
                                                <label>{{ translate('phone')}} <span class="text-danger">*</span></label>
                                                <input type="tel" class="form-control phone-input-with-country-picker-3" id="phone" required>
                                                <input type="hidden" id="shipping_phone_view" class="country-picker-phone-number-3" name="phone" readonly>
                                            </div>
                                        </div>
                                        @if(!auth('customer')->check())
                                            <div class="col-sm-12">
                                                <div class="form-group">
                                                    <label>{{ translate('email')}} <span class="text-danger">*</span></label>
                                                    <input type="email" class="form-control" name="email" id="email" required>
                                                </div>
                                            </div>
                                        @endif
                                        <div class="col-12">
                                            <div class="form-group">
                                                <label>{{ translate('address')}}</label>
                                                <textarea class="form-control" name="address" id="address" rows="3" required></textarea>
                                            </div>
                                        </div>
                                        <div class="col-sm-6">
                                            <div class="form-group">
                                                <label>{{ translate('city')}}</label>
                                                <input type="text" class="form-control" name="city" id="city">
                                            </div>
                                        </div>
                                        <div class="col-sm-6">
                                            <div class="form-group">
                                                <label>{{ translate('zip_code')}}</label>
                                                <input type="text" class="form-control" name="zip" id="zip">
                                            </div>
                                        </div>
                                    </div>
                                    <button type="button" class="btn btn--primary" id="save-address-btn">
                                        {{ translate('save_and_continue')}}
                                    </button>
                                </form>
                            </div>
                        </div>
                    @endif

                    {{-- SECTION 2: Payment Method --}}
                    <div class="card __card mb-3" id="payment-section" style="display: none;">
                        <div class="card-header bg-light">
                            <h5 class="mb-0">
                                <i class="tio-wallet"></i> 
                                {{ translate('2._payment_method')}}
                            </h5>
                        </div>
                        <div class="card-body">
                            @if($cash_on_delivery && $cash_on_delivery['status'])
                                <div class="form-check mb-3">
                                    <input class="form-check-input" type="radio" name="payment_method" id="cash-on-delivery" value="cash_on_delivery" checked>
                                    <label class="form-check-label d-flex align-items-center gap-2" for="cash-on-delivery">
                                        <img width="20" src="{{theme_asset(path: 'public/assets/front-end/img/cod.png')}}" alt="">
                                        {{ translate('cash_on_delivery')}}
                                    </label>
                                </div>
                            @endif

                            @if(auth('customer')->check() && $wallet_status == 1)
                                <div class="form-check mb-3">
                                    <input class="form-check-input" type="radio" name="payment_method" id="wallet-payment" value="wallet">
                                    <label class="form-check-label d-flex align-items-center gap-2" for="wallet-payment">
                                        <img width="20" src="{{theme_asset(path: 'public/assets/front-end/img/wallet.png')}}" alt="">
                                        {{ translate('wallet_payment')}}
                                    </label>
                                </div>
                            @endif

                            @if($digital_payment && $digital_payment['status'] == 1)
                                <div class="form-check mb-3">
                                    <input class="form-check-input" type="radio" name="payment_method" id="digital-payment" value="digital_payment">
                                    <label class="form-check-label d-flex align-items-center gap-2" for="digital-payment">
                                        <img width="20" src="{{theme_asset(path: 'public/assets/front-end/img/credit-card.png')}}" alt="">
                                        {{ translate('digital_payment')}}
                                    </label>
                                </div>
                            @endif

                            <div class="mt-3">
                                <button type="button" class="btn btn--primary" id="continue-to-review-btn">
                                    {{ translate('continue_to_review')}}
                                </button>
                            </div>
                        </div>
                    </div>

                    {{-- SECTION 3: Order Review --}}
                    <div class="card __card mb-3" id="review-section" style="display: none;">
                        <div class="card-header bg-light">
                            <h5 class="mb-0">
                                <i class="tio-checkmark-circle"></i> 
                                {{ translate('3._order_review')}}
                            </h5>
                        </div>
                        <div class="card-body">
                            <div class="alert alert-success">
                                <i class="tio-checkmark-circle-outlined"></i>
                                {{ translate('Please_review_your_order_and_place_it')}}
                            </div>
                            
                            @if($adminFlatShippingEnabled)
                                <div class="mb-3 p-3 bg-light rounded">
                                    <div class="d-flex justify-content-between">
                                        <span class="font-weight-bold">{{ translate('shipping')}}:</span>
                                        <span>{{ translate('admin_flat_rate') }} - {{ webCurrencyConverter(amount: \App\Utils\Helpers::getAdminFlatShippingRate()) }}</span>
                                    </div>
                                    <small class="text-muted">{{ translate('Flat_shipping_rate_applied_to_entire_order')}}</small>
                                </div>
                            @endif

                            <form method="get" id="checkout-form" action="{{route('checkout-complete')}}">
                                <input type="hidden" name="payment_method" id="final-payment-method">
                                <button type="submit" class="btn btn--primary btn-block">
                                    <i class="tio-shopping-cart"></i> {{ translate('place_order')}}
                                </button>
                            </form>
                        </div>
                    </div>
                </div>
            </section>

            {{-- Order Summary Sidebar --}}
            <aside class="col-lg-4 pt-lg-0 px-max-md-0">
                @include('web-views.partials._order-summary')
            </aside>
        </div>
    </div>
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
                // Clear form for new address
                $('#address-form')[0].reset();
            }
        });

        // Save address and show payment section
        $('#save-address-btn').click(function() {
            if($('#address-form')[0].checkValidity()) {
                // Submit address via AJAX
                $.ajax({
                    url: '{{ route("customer.choose-shipping-address") }}',
                    method: 'POST',
                    data: $('#address-form').serialize() + '&_token={{ csrf_token() }}',
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
