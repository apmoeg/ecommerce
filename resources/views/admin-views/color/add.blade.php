@extends('layouts.back-end.app')

@section('title', translate('color_Setup'))

@section('content')
<div class="content container-fluid">
    <div class="d-flex flex-wrap gap-2 align-items-center mb-3">
        <h2 class="h1 mb-0 d-flex align-items-center gap-2">
            {{ translate('color_Setup') }}
        </h2>
    </div>

    <div class="row g-3">
        <div class="col-md-12">
            <div class="card mb-3">
                <div class="card-body text-start">
                    <form action="{{ route('admin.color.add-new') }}" method="post">
                        @csrf
                        <div class="row">
                            <div class="col-md-6">
                                <div class="form-group">
                                    <label>{{ translate('color_Name') }} <span class="text-danger">*</span></label>
                                    <input type="text" name="name" class="form-control" placeholder="{{ translate('ex') }}: Red" required>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="form-group">
                                    <label>{{ translate('color_Code') }} <span class="text-danger">*</span></label>
                                    <input type="color" name="code" class="form-control form-control-color" required>
                                </div>
                            </div>
                        </div>

                        <div class="d-flex gap-3 justify-content-end">
                            <button type="reset" class="btn btn-secondary px-4">{{ translate('reset') }}</button>
                            <button type="submit" class="btn btn--primary px-4">{{ translate('submit') }}</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
