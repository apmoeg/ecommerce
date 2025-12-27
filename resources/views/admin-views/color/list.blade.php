@extends('layouts.back-end.app')

@section('title', translate('color_List'))

@section('content')
<div class="content container-fluid">
    <div class="mb-3">
        <h2 class="h1 mb-0 d-flex gap-2">
            {{ translate('color_List') }}
            <span class="badge badge-soft-dark radius-50 fz-14">{{ $colors->total() }}</span>
        </h2>
    </div>

    <div class="row mt-20">
        <div class="col-md-12">
            <div class="card">
                <div class="px-3 py-4">
                    <div class="row g-2 flex-grow-1">
                        <div class="col-sm-8 col-md-6 col-lg-4">
                            <form action="{{ url()->current() }}" method="GET">
                                <div class="input-group input-group-custom input-group-merge">
                                    <div class="input-group-prepend">
                                        <div class="input-group-text">
                                            <i class="tio-search"></i>
                                        </div>
                                    </div>
                                    <input id="datatableSearch_" type="search" name="searchValue" class="form-control"
                                        placeholder="{{ translate('search_by_color_name') }}" value="{{ request('searchValue') }}">
                                    <button type="submit" class="btn btn--primary input-group-text">
                                        {{ translate('search') }}
                                    </button>
                                </div>
                            </form>
                        </div>
                        <div class="col-sm-4 col-md-6 col-lg-8 d-flex justify-content-end">
                            <a href="{{ route('admin.color.add-new') }}" class="btn btn--primary">
                                <i class="tio-add"></i> {{ translate('add_new_color') }}
                            </a>
                        </div>
                    </div>
                </div>

                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table table-hover table-borderless table-thead-bordered table-nowrap table-align-middle card-table w-100 text-start">
                            <thead class="thead-light thead-50 text-capitalize">
                                <tr>
                                    <th>{{ translate('SL') }}</th>
                                    <th>{{ translate('name') }}</th>
                                    <th>{{ translate('code') }}</th>
                                    <th class="text-center">{{ translate('action') }}</th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach($colors as $key => $color)
                                <tr>
                                    <td>{{ $colors->firstItem() + $key }}</td>
                                    <td>{{ $color->name }}</td>
                                    <td>
                                        <div style="width: 30px; height: 30px; background: {{ $color->code }}; border-radius: 4px;"></div>
                                        <small>{{ $color->code }}</small>
                                    </td>
                                    <td class="text-center">
                                        <a class="btn btn-outline-info btn-sm" href="{{ route('admin.color.edit', [$color['id']]) }}">
                                            <i class="tio-edit"></i>
                                        </a>
                                        <form action="{{ route('admin.color.delete') }}" method="post" style="display:inline-block">
                                            @csrf
                                            <input type="hidden" name="id" value="{{ $color['id'] }}">
                                            <button type="submit" class="btn btn-outline-danger btn-sm"
                                                onclick="return confirm('{{ translate('are_you_sure_want_to_delete_this') }}')">
                                                <i class="tio-delete"></i>
                                            </button>
                                        </form>
                                    </td>
                                </tr>
                                @endforeach
                            </tbody>
                        </table>

                        @if(count($colors) == 0)
                            @include('layouts.back-end._empty-state', ['text' => 'no_color_found', 'image' => 'default'])
                        @endif
                    </div>
                </div>

                <div class="card-footer">
                    <div class="d-flex justify-content-end">
                        {{ $colors->links() }}
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
