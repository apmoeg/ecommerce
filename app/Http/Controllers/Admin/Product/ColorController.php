<?php

namespace App\Http\Controllers\Admin\Product;

use App\Enums\ViewPaths\Admin\Color;
use App\Http\Controllers\BaseController;
use App\Models\Color as ColorModel;
use Brian2694\Toastr\Facades\Toastr;
use Illuminate\Contracts\View\View;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Http\JsonResponse;
use Illuminate\Validation\Rule;

class ColorController extends BaseController
{
    public function index(?Request $request, ?string $type = null): View|Collection|LengthAwarePaginator|RedirectResponse|callable|null
    {
        return $this->getList($request);
    }

    public function getList(Request $request): View
    {
        $query = ColorModel::query();

        if ($request->filled('searchValue')) {
            $query->where('name', 'like', '%' . $request->searchValue . '%');
        }

        $colors = $query->orderBy('id', 'desc')
            ->paginate(getWebConfig(name: 'pagination_limit'));

        return view(Color::LIST[VIEW], compact('colors'));
    }

    public function getAddView(): View
    {
        return view(Color::ADD[VIEW]);
    }

    public function add(Request $request): RedirectResponse
    {
        $request->validate([
            'name' => ['required', 'string', 'max:120', 'unique:colors,name'],
            'code' => ['required', 'string', 'max:30', 'unique:colors,code'],
        ]);

        ColorModel::create([
            'name' => $request->name,
            'code' => $request->code,
        ]);

        Toastr::success(translate('color_added_successfully'));
        return redirect()->route('admin.color.list');
    }

    public function getUpdateView(string|int $id): View|RedirectResponse
    {
        $color = ColorModel::find($id);

        if (!$color) {
            Toastr::error(translate('color_not_found'));
            return redirect()->route('admin.color.list');
        }

        return view(Color::UPDATE[VIEW], compact('color'));
    }

    public function update(Request $request, string|int $id): RedirectResponse
    {
        $request->validate([
            'name' => [
                'required',
                'string',
                'max:30',
                Rule::unique('colors', 'name')->ignore($id),
            ],
            'code' => [
                'required',
                'string',
                'max:10',
                Rule::unique('colors', 'code')->ignore($id),
            ],
        ]);

        $color = ColorModel::find($id);

        if (!$color) {
            Toastr::error(translate('color_not_found'));
            return redirect()->route('admin.color.list');
        }

        $color->update([
            'name' => $request->name,
            'code' => $request->code,
        ]);

        Toastr::success(translate('color_updated_successfully'));
        return redirect()->route('admin.color.list');
    }

    public function delete(Request $request): RedirectResponse
    {
        $color = ColorModel::find($request->id);

        if (!$color) {
            Toastr::error(translate('color_not_found'));
            return redirect()->back();
        }

        $color->delete();

        Toastr::success(translate('color_deleted_successfully'));
        return redirect()->back();
    }

    public function updateStatus(Request $request): JsonResponse
    {
        $color = ColorModel::find($request->id);

        if (!$color) {
            return response()->json(['success' => 0, 'message' => translate('color_not_found')], 404);
        }

        $color->status = $request->get('status', 0);
        $color->save();

        return response()->json(['success' => 1, 'message' => translate('status_updated_successfully')]);
    }
}
