<?php

namespace App\Services;

use App\Enums\UserRole;
use App\Enums\ViewPaths\Admin\Product;
use App\Events\RestockProductNotificationEvent;
use App\Models\Color;
use App\Traits\FileManagerTrait;
use Illuminate\Support\Str;
use phpDocumentor\Reflection\Types\Boolean;
use Rap2hpoutre\FastExcel\FastExcel;
use function React\Promise\all;
use Illuminate\Support\Facades\Log;
use Carbon\Carbon;
use App\Models\Product as ProductModel;
use App\Models\ProductStock;
use App\Models\ProductSeo;
use App\Models\ProductTag;
use App\Models\Tag;
use App\Models\Translation;
use Illuminate\Support\Facades\DB;

class ProductService
{
    use FileManagerTrait;

    public function __construct(private readonly Color $color)
    {
    }

    public function getProcessedImages(object $request): array
    {
        $colorImageSerial = [];
        $imageNames = [];
        $storage = config('filesystems.disks.default') ?? 'public';
        if ($request->has('colors_active') && $request->has('colors') && count($request['colors']) > 0) {
            foreach ($request['colors'] as $color) {
                $color_ = Str::replace('#', '', $color);
                $img = 'color_image_' . $color_;
                if ($request->file($img)) {
                    $image = $this->upload(dir: 'product/', format: 'webp', image: $request->file($img));
                    $colorImageSerial[] = [
                        'color' => $color_,
                        'image_name' => $image,
                        'storage' => $storage,
                    ];
                    $imageNames[] = [
                        'image_name' => $image,
                        'storage' => $storage,
                    ];
                } else if ($request->has($img)) {
                    $image = $request->$img[0];
                    $colorImageSerial[] = [
                        'color' => $color_,
                        'image_name' => $image,
                        'storage' => $storage,
                    ];
                    $imageNames[] = [
                        'image_name' => $image,
                        'storage' => $storage,
                    ];
                }
            }
        }
        if ($request->file('images')) {
            foreach ($request->file('images') as $image) {
                $images = $this->upload(dir: 'product/', format: 'webp', image: $image);
                $imageNames[] = [
                    'image_name' => $images,
                    'storage' => $storage,
                ];
                if ($request->has('colors_active') && $request->has('colors') && count($request['colors']) > 0) {
                    $colorImageSerial[] = [
                        'color' => null,
                        'image_name' => $images,
                        'storage' => $storage,
                    ];
                }
            }
        }
        if (!empty($request->existing_images)) {
            foreach ($request->existing_images as $image) {
                $colorImageSerial[] = [
                    'color' => null,
                    'image_name' => $image,
                    'storage' => $storage,
                ];

                $imageNames[] = [
                    'image_name' => $image,
                    'storage' => $storage,
                ];
            }
        }
        return [
            'image_names' => $imageNames ?? [],
            'colored_image_names' => $colorImageSerial ?? []
        ];

    }

    public function getProcessedUpdateImages(object $request, object $product): array
    {
        $productImages = json_decode($product->images);
        $colorImageArray = [];
        $storage = config('filesystems.disks.default') ?? 'public';
        if ($request->has('colors_active') && $request->has('colors') && count($request->colors) > 0) {
            $dbColorImage = $product->color_image ? json_decode($product->color_image, true) : [];
            if (!$dbColorImage) {
                foreach ($productImages as $image) {
                    $image = is_string($image) ? $image : (array)$image;
                    $dbColorImage[] = [
                        'color' => null,
                        'image_name' => is_array($image) ? $image['image_name'] : $image,
                        'storage' => $image['storage'] ?? $storage,
                    ];
                }
            }

            $dbColorImageFinal = [];
            if ($dbColorImage) {
                foreach ($dbColorImage as $colorImage) {
                    if ($colorImage['color']) {
                        $dbColorImageFinal[] = $colorImage['color'];
                    }
                }
            }

            $inputColors = [];
            foreach ($request->colors as $color) {
                $inputColors[] = str_replace('#', '', $color);
            }
            $colorImageArray = $dbColorImage;

            foreach ($inputColors as $color) {
                if (!in_array($color, $dbColorImageFinal)) {
                    $image = 'color_image_' . $color;
                    if ($request->file($image)) {
                        $imageName = $this->upload(dir: 'product/', format: 'webp', image: $request->file($image));
                        $productImages[] = [
                            'image_name' => $imageName,
                            'storage' => $storage,
                        ];
                        $colorImages = [
                            'color' => $color,
                            'image_name' => $imageName,
                            'storage' => $storage,
                        ];
                        $colorImageArray[] = $colorImages;
                    }
                }
            }
        }

        if ($request->file('images')) {
            foreach ($request->file('images') as $image) {
                $imageName = $this->upload(dir: 'product/', format: 'webp', image: $image);
                $productImages[] = [
                    'image_name' => $imageName,
                    'storage' => $storage,
                ];
                if ($request->has('colors_active') && $request->has('colors') && count($request->colors) > 0) {
                    $colorImageArray[] = [
                        'color' => null,
                        'image_name' => $imageName,
                        'storage' => $storage,
                    ];
                }
            }
        }
        return [
            'image_names' => $productImages ?? [],
            'colored_image_names' => $colorImageArray ?? []
        ];
    }

    public function getCategoriesArray(object $request): array
    {
        $category = [];
        if ($request['category_id'] != null) {
            $category[] = [
                'id' => $request['category_id'],
                'position' => 1,
            ];
        }
        if ($request['sub_category_id'] != null) {
            $category[] = [
                'id' => $request['sub_category_id'],
                'position' => 2,
            ];
        }
        if ($request['sub_sub_category_id'] != null) {
            $category[] = [
                'id' => $request['sub_sub_category_id'],
                'position' => 3,
            ];
        }
        return $category;
    }

    public function getColorsObject(object $request): bool|string
    {
        if ($request->has('colors_active') && $request->has('colors') && count($request['colors']) > 0) {
            $colors = $request['product_type'] == 'physical' ? json_encode($request['colors']) : json_encode([]);
        } else {
            $colors = json_encode([]);
        }
        return $colors;
    }

    public function getSlug(object $request): string
    {
        return Str::slug($request['name'][array_search('en', $request['lang'])], '-') . '-' . Str::random(6);
    }

    public function getChoiceOptions(object $request): array
    {
        $choice_options = [];
        if ($request->has('choice')) {
            foreach ($request->choice_no as $key => $no) {
                $str = 'choice_options_' . $no;
                $item['name'] = 'choice_' . $no;
                $item['title'] = $request->choice[$key];
                $item['options'] = explode(',', implode('|', $request[$str]));
                $choice_options[] = $item;
            }
        }
        return $choice_options;
    }

    public function getOptions(object $request): array
    {
        $options = [];
        if ($request->has('colors_active') && $request->has('colors') && count($request->colors) > 0) {
            $options[] = $request->colors;
        }
        if ($request->has('choice_no')) {
            foreach ($request->choice_no as $no) {
                $name = 'choice_options_' . $no;
                $myString = implode('|', $request[$name]);
                $optionArray = array_filter(explode(',', $myString), function ($value) {
                    return $value !== '';
                });
                $options[] = $optionArray;
            }
        }
        return $options;
    }

    public function getCombinations(array $arrays): array
    {
        $result = [[]];
        foreach ($arrays as $property => $property_values) {
            $tmp = [];
            foreach ($result as $result_item) {
                foreach ($property_values as $property_value) {
                    $tmp[] = array_merge($result_item, [$property => $property_value]);
                }
            }
            $result = $tmp;
        }
        return $result;
    }

    public function getSkuCombinationView(object $request, object $product = null): string
    {
        $colorsActive = ($request->has('colors_active') && $request->has('colors') && count($request['colors']) > 0) ? 1 : 0;
        $unitPrice = $request['unit_price'];
        $productName = $request['name'][array_search('en', $request['lang'])];
        $options = $this->getOptions(request: $request);
        $combinations = $this->getCombinations(arrays: $options);
        $combinations = $this->generatePhysicalVariationCombination(request: $request, options: $options, combinations: $combinations, product: $product);

        if ($product) {
            return view(Product::SKU_EDIT_COMBINATION[VIEW], compact('combinations', 'unitPrice', 'colorsActive', 'productName'))->render();
        }else{
            return view(Product::SKU_COMBINATION[VIEW], compact('combinations', 'unitPrice', 'colorsActive', 'productName'))->render();
        }
    }

    public function getVariations(object $request, array $combinations): array
    {
        $variations = [];
        if (isset($combinations[0]) && count($combinations[0]) > 0) {
            foreach ($combinations as $combination) {
                $str = '';
                foreach ($combination as $combinationKey => $item) {
                    if ($combinationKey > 0) {
                        $str .= '-' . str_replace(' ', '', $item);
                    } else {
                        if ($request->has('colors_active') && $request->has('colors') && count($request['colors']) > 0) {
                            $color_name = $this->color->where('code', $item)->first()->name;
                            $str .= $color_name;
                        } else {
                            $str .= str_replace(' ', '', $item);
                        }
                    }
                }
                $item = [];
                $item['type'] = $str;
                $item['price'] = currencyConverter(abs($request['price_' . str_replace('.', '_', $str)]));
                $item['sku'] = $request['sku_' . str_replace('.', '_', $str)];
                $item['qty'] = abs($request['qty_' . str_replace('.', '_', $str)]);
                $variations[] = $item;
            }
        }

        return $variations;
    }

    public function getTotalQuantity(array $variations): int
    {
        $sum = 0;
        foreach ($variations as $item) {
            if (isset($item['qty'])) {
                $sum += $item['qty'];
            }
        }
        return $sum;
    }

    public function getCategoryDropdown(object $request, object $categories): string
    {
        $dropdown = '<option value="' . 0 . '" disabled selected>---' . translate("Select") . '---</option>';
        foreach ($categories as $row) {
            if ($row->id == $request['sub_category']) {
                $dropdown .= '<option value="' . $row->id . '" selected >' . $row->defaultName . '</option>';
            } else {
                $dropdown .= '<option value="' . $row->id . '">' . $row->defaultName . '</option>';
            }
        }

        return $dropdown;
    }

    public function deleteImages(object $product): bool
    {
        foreach (json_decode($product['images'], true) as $image) {
            $this->delete(filePath: '/product/' . (isset($image['image_name']) ? $image['image_name'] : $image));
        }
        $this->delete(filePath: '/product/thumbnail/' . $product['thumbnail']);

        return true;
    }

    public function deletePreviewFile(object $product): bool
    {
        if ($product['preview_file']) {
            $this->delete(filePath: '/product/preview/' . $product['preview_file']);
        }
        return true;
    }

    public function deleteImage(object $request, object $product): array
    {
        $colors = json_decode($product['colors']);
        $color_image = json_decode($product['color_image']);
        $images = [];
        $color_images = [];
        if ($colors && $color_image) {
            foreach ($color_image as $img) {
                if ($img->color != $request['color'] && $img?->image_name != $request['name']) {
                    $color_images[] = [
                        'color' => $img->color != null ? $img->color : null,
                        'image_name' => $img->image_name,
                        'storage' => $img?->storage ?? 'public',
                    ];
                }
            }
        }

        foreach (json_decode($product['images']) as $image) {
            $imageName = $image?->image_name ?? $image;
            if ($imageName != $request['name']) {
                $images[] = $image;
            }
        }

        return [
            'images' => $images,
            'color_images' => $color_images
        ];
    }

    public function getAddProductData(object $request, string $addedBy): array
    {
        $storage = config('filesystems.disks.default') ?? 'public';
        $processedImages = $this->getProcessedImages(request: $request); //once the images are processed do not call this function again just use the variable
        $combinations = $this->getCombinations($this->getOptions(request: $request));
        $variations = $this->getVariations(request: $request, combinations: $combinations);
        $stockCount = count($combinations[0]) > 0 ? $this->getTotalQuantity(variations: $variations) : (integer)$request['current_stock'];

        $digitalFile = '';
        if ($request['product_type'] == 'digital' && $request['digital_product_type'] == 'ready_product' && $request['digital_file_ready']) {
            $digitalFile = $this->fileUpload(dir: 'product/digital-product/', format: $request['digital_file_ready']->getClientOriginalExtension(), file: $request['digital_file_ready']);
        }

        $previewFile = $request['product_type'] == 'digital' && $request->existing_preview_file ? $request->existing_preview_file : '';
        if ($request['product_type'] == 'digital' && $request->has('preview_file') && $request['preview_file']) {
            $previewFile = $this->fileUpload(dir: 'product/preview/', format: $request['preview_file']->getClientOriginalExtension(), file: $request['preview_file']);
        }

        $digitalFileOptions = $this->getDigitalVariationOptions(request: $request);
        $digitalFileCombinations = $this->getDigitalVariationCombinations(arrays: $digitalFileOptions);

        return [
            'added_by' => $addedBy,
            'user_id' => $addedBy == 'admin' ? auth('admin')->id() : auth('seller')->id(),
            'name' => $request['name'][array_search('en', $request['lang'])],
            'code' => $request['code'],
            'slug' => $this->getSlug($request),
            'category_ids' => json_encode($this->getCategoriesArray(request: $request)),
            'category_id' => $request['category_id'],
            'sub_category_id' => $request['sub_category_id'],
            'sub_sub_category_id' => $request['sub_sub_category_id'],
            'brand_id' => $request['product_type'] == 'physical' ? $request['brand_id'] : null,
            'unit' => $request['product_type'] == 'physical' ? $request['unit'] : null,
            'digital_product_type' => $request['product_type'] == 'digital' ? $request['digital_product_type'] : null,
            'digital_file_ready' => $digitalFile,
            'digital_file_ready_storage_type' => $digitalFile ? $storage : null,
            'product_type' => $request['product_type'],
            'details' => $request['description'][array_search('en', $request['lang'])],
            'colors' => $this->getColorsObject(request: $request),
            'choice_options' => $request['product_type'] == 'physical' ? json_encode($this->getChoiceOptions(request: $request)) : json_encode([]),
            'variation' => $request['product_type'] == 'physical' ? json_encode($variations) : json_encode([]),
            'digital_product_file_types' => $request->has('extensions_type') ? $request->get('extensions_type') : [],
            'digital_product_extensions' => $digitalFileCombinations,
            'unit_price' => currencyConverter(amount: $request['unit_price']),
            'purchase_price' => 0,
            'tax' => $request['tax_type'] == 'flat' ? currencyConverter(amount: $request['tax']) : $request['tax'],
            'tax_type' => $request->get('tax_type', 'percent'),
            'tax_model' => $request['tax_model'],
            'discount' => $request['discount_type'] == 'flat' ? currencyConverter(amount: $request['discount']) : $request['discount'],
            'discount_type' => $request['discount_type'],
            'attributes' => $request['product_type'] == 'physical' ? json_encode($request['choice_attributes']) : json_encode([]),
            'current_stock' => $request['product_type'] == 'physical' ? abs($stockCount) : 999999999,
            'minimum_order_qty' => $request['minimum_order_qty'],
            'video_provider' => 'youtube',
            'video_url' => $request['video_url'],
            'status' => $addedBy == 'admin' ? 1 : 0,
            'request_status' => $addedBy == 'admin' ? 1 : (getWebConfig(name: 'new_product_approval') == 1 ? 0 : 1),
            'shipping_cost' => $request['product_type'] == 'physical' ? currencyConverter(amount: $request['shipping_cost']) : 0,
            'multiply_qty' => ($request['product_type'] == 'physical') ? ($request['multiply_qty'] == 'on' ? 1 : 0) : 0, //to be changed in form multiply_qty
            'color_image' => json_encode($processedImages['colored_image_names']),
            'images' => json_encode($processedImages['image_names']),
            'thumbnail' => $request->has('image') ? $this->upload(dir: 'product/thumbnail/', format: 'webp', image: $request['image']) : $request->existing_thumbnail,
            'thumbnail_storage_type' => $request->has('image') ? $storage : null,
            'preview_file' => $previewFile,
            'preview_file_storage_type' => $request->has('image') ? $storage : $request->get('existing_preview_file_storage_type', null),
            'meta_title' => $request['meta_title'],
            'meta_description' => $request['meta_description'],
            'meta_image' => $request->has('meta_image') ? $this->upload(dir: 'product/meta/', format: 'webp', image: $request['meta_image']) : $request->existing_meta_image,
        ];
    }

    public function getUpdateProductData(object $request, object $product, string $updateBy): array
    {
        $storage = config('filesystems.disks.default') ?? 'public';
        $processedImages = $this->getProcessedUpdateImages(request: $request, product: $product);
        $combinations = $this->getCombinations($this->getOptions(request: $request));
        $variations = $this->getVariations(request: $request, combinations: $combinations);
        $stockCount = isset($combinations[0]) && count($combinations[0]) > 0 ? $this->getTotalQuantity(variations: $variations) : (integer)$request['current_stock'];

        if ($request->has('extensions_type') && $request->has('digital_product_variant_key')) {
            $digitalFile = null;
        } else {
            $digitalFile = $product['digital_file_ready'];
        }
        if ($request['product_type'] == 'digital') {
            if ($request['digital_product_type'] == 'ready_product' && $request->hasFile('digital_file_ready')) {
                $digitalFile = $this->update(dir: 'product/digital-product/', oldImage: $product['digital_file_ready'], format: $request['digital_file_ready']->getClientOriginalExtension(), image: $request['digital_file_ready'], fileType: 'file');
            } elseif (($request['digital_product_type'] == 'ready_after_sell') && $product['digital_file_ready']) {
                $digitalFile = null;
                // $this->delete(filePath: 'product/digital-product/' . $product['digital_file_ready']);
            }
        } elseif ($request['product_type'] == 'physical' && $product['digital_file_ready']) {
            $digitalFile = null;
            // $this->delete(filePath: 'product/digital-product/' . $product['digital_file_ready']);
        }

        $digitalFileOptions = $this->getDigitalVariationOptions(request: $request);
        $digitalFileCombinations = $this->getDigitalVariationCombinations(arrays: $digitalFileOptions);

        $dataArray = [
            'name' => $request['name'][array_search('en', $request['lang'])],
            'code' => $request['code'],
            'product_type' => $request['product_type'],
            'category_ids' => json_encode($this->getCategoriesArray(request: $request)),
            'category_id' => $request['category_id'],
            'sub_category_id' => $request['sub_category_id'],
            'sub_sub_category_id' => $request['sub_sub_category_id'],
            'brand_id' => $request['product_type'] == 'physical' ? $request['brand_id'] : null,
            'unit' => $request['product_type'] == 'physical' ? $request['unit'] : null,
            'digital_product_type' => $request['product_type'] == 'digital' ? $request['digital_product_type'] : null,
            'details' => $request['description'][array_search('en', $request['lang'])],
            'colors' => $this->getColorsObject(request: $request),
            'choice_options' => $request['product_type'] == 'physical' ? json_encode($this->getChoiceOptions(request: $request)) : json_encode([]),
            'variation' => $request['product_type'] == 'physical' ? json_encode($variations) : json_encode([]),
            'digital_product_file_types' => $request->has('extensions_type') ? $request->get('extensions_type') : [],
            'digital_product_extensions' => $digitalFileCombinations,
            'unit_price' => currencyConverter(amount: $request['unit_price']),
            'purchase_price' => 0,
            'tax' => $request['tax_type'] == 'flat' ? currencyConverter(amount: $request['tax']) : $request['tax'],
            'tax_type' => $request['tax_type'],
            'tax_model' => $request['tax_model'],
            'discount' => $request['discount_type'] == 'flat' ? currencyConverter(amount: $request['discount']) : $request['discount'],
            'discount_type' => $request['discount_type'],
            'attributes' => $request['product_type'] == 'physical' ? json_encode($request['choice_attributes']) : json_encode([]),
            'current_stock' => $request['product_type'] == 'physical' ? abs($stockCount) : 999999999,
            'minimum_order_qty' => $request['minimum_order_qty'],
            'video_provider' => 'youtube',
            'video_url' => $request['video_url'],
            'multiply_qty' => ($request['product_type'] == 'physical') ? ($request['multiply_qty'] == 'on' ? 1 : 0) : 0,
            'color_image' => json_encode($processedImages['colored_image_names']),
            'images' => json_encode($processedImages['image_names']),
            'digital_file_ready' => $digitalFile,
            'digital_file_ready_storage_type' => $request->has('digital_file_ready') ? $storage : $product['digital_file_ready_storage_type'],
            'meta_title' => $request['meta_title'],
            'meta_description' => $request['meta_description'],
            'meta_image' => $request->file('meta_image') ? $this->update(dir: 'product/meta/', oldImage: $product['meta_image'], format: 'png', image: $request['meta_image']) : $product['meta_image'],
        ];

        if ($request->file('image')) {
            $dataArray += [
                'thumbnail' => $this->update(dir: 'product/thumbnail/', oldImage: $product['thumbnail'], format: 'webp', image: $request['image'], fileType: 'image'),
                'thumbnail_storage_type' => $storage
            ];
        }
        if ($request->file('preview_file')) {
            $dataArray += [
                'preview_file' => $this->update(dir: 'product/preview/', oldImage: $product['preview_file'], format: $request['preview_file']->getClientOriginalExtension(), image: $request['preview_file'], fileType: 'file'),
                'preview_file_storage_type' => $storage
            ];
        }
        if ($request['product_type'] == 'physical' && $product['preview_file']) {
            $this->delete(filePath: '/product/preview/' . $product['preview_file']);
            $dataArray += [
                'preview_file' => null,
            ];
        }

        if ($updateBy == 'seller' && getWebConfig(name: 'product_wise_shipping_cost_approval') == 1 && $product->shipping_cost != currencyConverter($request->shipping_cost)) {
            $dataArray += [
                'temp_shipping_cost' => currencyConverter($request->shipping_cost),
                'is_shipping_cost_updated' => 0,
                'shipping_cost' => $product->shipping_cost,
            ];
        } else {
            $dataArray += [
                'shipping_cost' => $request['product_type'] == 'physical' ? currencyConverter(amount: $request['shipping_cost']) : 0,
            ];
        }
        if ($updateBy == 'seller' && $product->request_status == 2) {
            $dataArray += [
                'request_status' => 0
            ];
        }

        if ($updateBy == 'admin' && $product->added_by == 'seller' && $product->request_status == 2) {
            $dataArray += [
                'request_status' => 1
            ];
        }

        return $dataArray;
    }

    /**
     * Import or update bulk products from a spreadsheet.
     *
     * Update if any of (id, sku, barcode, asin) matches an existing product.
     * Otherwise create a new product. Only non‐empty columns are written on update.
     *
     * @param  object $request  must contain 'products_file'
     * @param  string $addedBy  'admin' or 'seller'
     * @return array            ['status'=>bool, 'message'=>string, 'products'=>ProductModel[]]
     */
    public function getImportBulkProductData(object $request, string $addedBy): array
    {
        $storage = config('filesystems.disks.default', 'public');
        DB::beginTransaction();

        // 1) Load the spreadsheet
        try {
            $rows = (new FastExcel)->import($request->file('products_file'));
        } catch (\Exception $e) {
            Log::error('Error importing file', ['error' => $e]);
            DB::rollBack();
            return [
                'status'   => false,
                'message'  => translate('you_have_uploaded_a_wrong_format_file') . ', ' . translate('please_upload_the_right_file'),
                'products' => [],
            ];
        }

        if (empty($rows)) {
            Log::warning('No data found in file');
            DB::rollBack();
            return [
                'status'   => false,
                'message'  => translate('you_need_to_upload_with_proper_data'),
                'products' => [],
            ];
        }

        // 2) Define allowed columns and required ones for creating new products
        $allowedColumns = [
            'id','category_id','sub_category_id','sub_sub_category_id','name','details','detailsEN',
            'thumbnail','images','sku','barcode','asin','nameEN','current_stock','status',
            'seo_title','seo_description','keywords','brand_id','refundable','discount',
            'discount_type','youtube_video_url','minimum_order_qty','unit','unit_price',
            'purchase_price','meta_image','tax','tax_type','shipping_cost','seller_id',
        ];
        $requiredForCreate = ['name','unit_price','category_id'];

        $imported = [];

        foreach ($rows as $idx => $rawRow) {
            // Trim and drop truly empty cells
            $row = array_filter(
                array_map('trim', $rawRow),
                fn($v) => $v !== ''
            );

            // Reject unexpected columns
            if ($diff = array_diff(array_keys($row), $allowedColumns)) {
                Log::error("Row {$idx} has invalid columns", ['cols' => $diff]);
                DB::rollBack();
                return [
                    'status'   => false,
                    'message'  => translate('Please_upload_the_correct_format_file'),
                    'products' => [],
                ];
            }

            // Find existing product by id|sku|barcode|asin (with seller context)
            $product = $this->findExistingProduct($row);

            if ($product) {
                // UPDATE path: only apply non‑empty fields
                $this->applyUpdateFields($product, $row, $storage, $addedBy);
            } else {
                // CREATE path: enforce required columns
                if ($missing = array_diff($requiredForCreate, array_keys($row))) {
                    Log::error("Row {$idx} missing required for create", ['missing' => $missing]);
                    DB::rollBack();
                    return [
                        'status'   => false,
                        'message'  => translate('Please fill ' . implode(', ', $missing)),
                        'products' => [],
                    ];
                }
                $product = $this->applyCreateFields($row, $storage, $addedBy);
                if (! $product) {
                    // If creation failed, skip
                    continue;
                }
            }

            $imported[] = $product;
        }

        DB::commit();

        return [
            'status'   => true,
            'message'  => count($imported) . ' - ' . translate('products_imported_successfully'),
            'products' => $imported,
        ];
    }

    /**
     * Try to find an existing product by id, sku, barcode or asin,
     * requiring seller_id for non-id lookups.
     */
    protected function findExistingProduct(array $row): ?ProductModel
    {
        // Match by primary key
        if (!empty($row['id'])) {
            return ProductModel::find((int)$row['id']);
        }

        // For code-based lookups, seller_id must be present
        if (!isset($row['seller_id'])) {
            return null;
        }
        $sellerId = (int)$row['seller_id'];
        $queryBase = ProductModel::query();

        // Restrict to admin versus seller products
        if ($sellerId === 0) {
            $queryBase->where('added_by', 'admin');
        } else {
            $queryBase->where('added_by', 'seller')->where('user_id', $sellerId);
        }

        if (!empty($row['sku'])) {
            return $queryBase->where('code', $row['sku'])->first();
        }
        if (!empty($row['barcode'])) {
            return $queryBase->where('barcode', $row['barcode'])->first();
        }
        if (!empty($row['asin'])) {
            return $queryBase->where('asin', $row['asin'])->first();
        }

        return null;
    }

    /**
     * Assemble category_ids JSON array from category_id / sub_category_id / sub_sub_category_id.
     */
    protected function buildCategoryIds(array $row): array
    {
        $ids = [];
        if (!empty($row['category_id'])) {
            $ids[] = ['id' => (string)$row['category_id'], 'position' => 1];
        }
        if (!empty($row['sub_category_id'])) {
            $ids[] = ['id' => (string)$row['sub_category_id'], 'position' => 2];
        }
        if (!empty($row['sub_sub_category_id'])) {
            $ids[] = ['id' => (string)$row['sub_sub_category_id'], 'position' => 3];
        }
        return $ids;
    }

    /**
     * Apply only the non‑empty values from $row to an existing product.
     */
    protected function applyUpdateFields(
        ProductModel $product,
        array $row,
        string $storage,
        string $addedBy
    ): void {
        // Always update raw category_id columns if provided
        if (isset($row['category_id'])) {
            $product->category_id = (int)$row['category_id'];
        }
        if (isset($row['sub_category_id'])) {
            $product->sub_category_id = (int)$row['sub_category_id'];
        }
        if (isset($row['sub_sub_category_id'])) {
            $product->sub_sub_category_id = (int)$row['sub_sub_category_id'];
        }
        // Rebuild JSON category_ids if any category columns changed
        if (isset($row['category_id'], $row['sub_category_id'], $row['sub_sub_category_id'])) {
            $product->category_ids = json_encode($this->buildCategoryIds($row));
        }

        foreach ($row as $col => $val) {
            if ($val === '') {
                continue;
            }
            switch ($col) {
                case 'id':
                    // do not reassign
                    break;

                case 'seller_id':
                    // override owner if needed
                    if ((int)$val > 0) {
                        $product->added_by = 'seller';
                        $product->user_id  = (int)$val;
                    } else {
                        $product->added_by = 'admin';
                    }
                    break;

                case 'name':
                    $product->name = $val;
                    Translation::updateOrCreate(
                        [
                            'translationable_type' => ProductModel::class,
                            'translationable_id'   => $product->id,
                            'locale'               => 'eg',
                            'key'                  => 'name',
                        ],
                        ['value' => $val]
                    );
                    break;

                case 'details':
                    $product->details = $val;
                    Translation::updateOrCreate(
                        [
                            'translationable_type' => ProductModel::class,
                            'translationable_id'   => $product->id,
                            'locale'               => 'eg',
                            'key'                  => 'description',
                        ],
                        ['value' => $val]
                    );
                    break;

/*                case 'nameEN':
                    $product->name = $val;
                    Translation::updateOrCreate(
                        [
                            'translationable_type' => ProductModel::class,
                            'translationable_id'   => $product->id,
                            'locale'               => 'en',
                            'key'                  => 'name',
                        ],
                        ['value' => $val]
                    );
                    break;

                case 'detailsEN':
                    $product->details = $val;
                    Translation::updateOrCreate(
                        [
                            'translationable_type' => ProductModel::class,
                            'translationable_id'   => $product->id,
                            'locale'               => 'en',
                            'key'                  => 'description',
                        ],
                        ['value' => $val]
                    );
                    break;*/

                case 'thumbnail':
                    $product->thumbnail = $val;
                    break;

                case 'images':
                    $imgs = array_map(fn($i) => ['image_name' => trim($i), 'storage' => $storage], explode(',', $val));
                    $product->images = json_encode($imgs);
                    break;

                case 'sku':
                    $product->code = $val;
                    break;

                case 'barcode':
                    $product->barcode = $val;
                    break;

                case 'asin':
                    $product->asin = $val;
                    break;

                case 'current_stock':
                    $product->current_stock = (int)$val;
                    break;

                case 'status':
                    $product->status = (int)$val;
                    break;

                case 'unit_price':
                    $product->unit_price = (float)$val;
                    break;

                case 'purchase_price':
                    $product->purchase_price = (float)$val;
                    break;

                case 'seo_title':
                    $product->meta_title = $val;
                    break;

                case 'seo_description':
                    $product->meta_description = $val;
                    break;

                case 'keywords':
                    ProductTag::where('product_id', $product->id)->delete();
                    foreach (explode(',', $val) as $rawTag) {
                        $t = trim($rawTag);
                        if ($t === '') continue;
                        $tagRec = Tag::firstOrCreate(['tag' => $t]);
                        ProductTag::create(['product_id' => $product->id, 'tag_id' => $tagRec->id]);
                    }
                    break;

                case 'brand_id':
                    $product->brand_id = (int)$val;
                    break;

                case 'refundable':
                    $product->refundable = (int)$val;
                    break;

                case 'discount':
                    $product->discount = (float)$val;
                    break;

                case 'discount_type':
                    $product->discount_type = $val;
                    break;

                case 'youtube_video_url':
                    $product->video_url = $val;
                    break;

                case 'minimum_order_qty':
                    $product->minimum_order_qty = (int)$val;
                    break;

                case 'unit':
                    $product->unit = $val;
                    break;

                case 'meta_image':
                    $product->meta_image = $val;
                    break;

                case 'tax':
                    $product->tax = (float)$val;
                    break;

                case 'tax_type':
                    $product->tax_type = $val;
                    break;

                case 'shipping_cost':
                    $product->shipping_cost = (float)$val;
                    break;
            }
        }

        try {
            $product->save();
        } catch (\Exception $e) {
            Log::error('Error updating product', ['exception' => $e, 'id' => $product->id]);
        }

        // Update or create SEO record
        ProductSeo::updateOrCreate(
            ['product_id' => $product->id],
            [
                'title'                   => $product->meta_title,
                'description'             => $product->meta_description,
                'index'                   => 'index',
                'no_follow'               => 'no_follow',
                'no_image_index'          => 'no_image_index',
                'no_archive'              => 'no_archive',
                'no_snippet'              => 'no_snippet',
                'max_snippet'             => 'max_snippet',
                'max_snippet_value'       => 'max_snippet_value',
                'max_video_preview'       => 'max_video_preview',
                'max_video_preview_value' => 'max_video_preview_value',
                'max_image_preview'       => 'max_image_preview',
                'max_image_preview_value' => 'max_image_preview_value',
                'image'                   => $product->meta_image,
            ]
        );
    }

    /**
     * Create a brand‑new product with full data.
     */
    protected function applyCreateFields(
        array $row,
        string $storage,
        string $addedBy
    ): ?ProductModel {
        $product = new ProductModel();
        if (!empty($row['id'])) {
            $product->id = (int) $row['id'];
        }
        // Per‑row seller override
        if (!empty($row['seller_id']) && (int)$row['seller_id'] > 0) {
            $product->added_by = 'seller';
            $product->user_id  = (int)$row['seller_id'];
        } else {
            $product->added_by = $addedBy;
            $product->user_id  = $addedBy === 'admin'
                ? auth('admin')->id()
                : auth('seller')->id();
        }

        // Slug & categories
        $slugSource = $row['nameEN'] ?? $row['name'];
        $slugSuffix = Str::slug($row['sku'] ?? Str::random(6), '-') ?: Str::random(6);
        $product->slug = Str::slug($slugSource, '-') . '-' . $slugSuffix;

        // Assign raw category columns
        $product->category_id     = (int)$row['category_id'];
        $product->sub_category_id = isset($row['sub_category_id']) ? (int)$row['sub_category_id'] : null;
        $product->sub_sub_category_id = isset($row['sub_sub_category_id']) ? (int)$row['sub_sub_category_id'] : null;
        // Build JSON category_ids
        $product->category_ids = json_encode($this->buildCategoryIds($row));

        // Core fields
        $product->name            = $row['nameEN'] ?? $row['name'];
        $product->details         = $row['detailsEN'] ?? ($row['details'] ?? '');
        $product->thumbnail       = $row['thumbnail'] ?? 'def.png';
        $product->images          = isset($row['images'])
            ? json_encode(array_map(fn($i) => ['image_name'=>trim($i),'storage'=>$storage], explode(',', $row['images'])))
            : json_encode([['image_name'=>'def.png','storage'=>$storage]]);

        $product->code            = $row['sku'] ?? null;
        $product->barcode         = $row['barcode'] ?? null;
        $product->asin            = $row['asin'] ?? null;
        $product->brand_id        = (int)($row['brand_id'] ?? 1);
        $product->refundable      = isset($row['refundable']) ? (int)$row['refundable'] : 1;
        $product->discount        = (float)($row['discount'] ?? 0);
        $product->discount_type   = $row['discount_type'] ?? 'percent';
        $product->tax             = (float)($row['tax'] ?? 0);
        $product->tax_type        = $row['tax_type'] ?? 'percent';
        $product->shipping_cost   = (float)($row['shipping_cost'] ?? 0);
        $product->unit            = $row['unit'] ?? 'PC';
        $product->minimum_order_qty = (int)($row['minimum_order_qty'] ?? 1);
        $product->request_status = $addedBy == 'admin' ? 1 : (getWebConfig(name: 'new_product_approval') == 1 ? 0 : 1);
        $product->variation            = json_encode([]);
        $product->choice_options            = json_encode([]);
        $product->colors            = json_encode([]);
        $product->color_image            = json_encode([]);
        $product->attributes            = json_encode([]);

        $product->current_stock   = (int)($row['current_stock'] ?? 0);
        $product->status          = isset($row['status'])
            ? (int)$row['status']
            : (($product->current_stock > 0) ? 1 : 0);

        $product->unit_price      = (float)($row['unit_price'] ?? 0);
        $product->purchase_price  = (float)($row['purchase_price'] ?? 0);

        // SEO defaults
        $product->meta_title       = $row['seo_title'] ?? $product->name;
        $product->meta_description = $row['seo_description'] ?? Str::before($product->details, "\n");
        $keywords                  = $row['keywords'] ?? $product->name;
        $product->video_provider   = 'youtube';
        $product->video_url        = $row['youtube_video_url'] ?? null;
        $product->meta_image       = $row['meta_image'] ?? 'def.png';

        // Save new product
        try {
            $product->save();
        } catch (\Exception $e) {
            Log::error('Error creating product', ['exception' => $e]);
            return null;
        }

        // SEO record
        ProductSeo::updateOrCreate(
            ['product_id' => $product->id],
            [
                'title'                   => $product->meta_title,
                'description'             => $product->meta_description,
                'index'                   => 'index',
                'no_follow'               => 'no_follow',
                'no_image_index'          => 'no_image_index',
                'no_archive'              => 'no_archive',
                'no_snippet'              => 'no_snippet',
                'max_snippet'             => 'max_snippet',
                'max_snippet_value'       => 'max_snippet_value',
                'max_video_preview'       => 'max_video_preview',
                'max_video_preview_value' => 'max_video_preview_value',
                'max_image_preview'       => 'max_image_preview',
                'max_image_preview_value' => 'max_image_preview_value',
                'image'                   => $product->meta_image,
            ]
        );

        // Tags
        foreach (explode(',', $keywords) as $rawTag) {
            $t = trim($rawTag);
            if ($t === '') continue;
            $tagRec = Tag::firstOrCreate(['tag' => $t]);
            ProductTag::create(['product_id' => $product->id, 'tag_id' => $tagRec->id]);
        }

        // Translations
        if (!empty($row['name'])) {
            Translation::updateOrCreate(
                [
                    'translationable_type' => ProductModel::class,
                    'translationable_id'   => $product->id,
                    'locale'               => 'eg',
                    'key'                  => 'name',
                ],
                ['value' => $row['name']]
            );
        }
        if (!empty($row['details'])) {
            Translation::updateOrCreate(
                [
                    'translationable_type' => ProductModel::class,
                    'translationable_id'   => $product->id,
                    'locale'               => 'eg',
                    'key'                  => 'description',
                ],
                ['value' => $row['details']]
            );
        }
/*        if (!empty($row['nameEN'])) {
            Translation::updateOrCreate(
                [
                    'translationable_type' => ProductModel::class,
                    'translationable_id'   => $product->id,
                    'locale'               => 'en',
                    'key'                  => 'name',
                ],
                ['value' => $row['nameEN']]
            );
        }
        if (!empty($row['detailsEN'])) {
            Translation::updateOrCreate(
                [
                    'translationable_type' => ProductModel::class,
                    'translationable_id'   => $product->id,
                    'locale'               => 'en',
                    'key'                  => 'description',
                ],
                ['value' => $row['detailsEN']]
            );
        }*/

        return $product;
    }


    public function checkLimitedStock(object $products): bool
    {
        foreach ($products as $product) {
            if ($product['product_type'] == 'physical' && $product['current_stock'] < (int)getWebConfig('stock_limit')) {
                return true;
            }
        }
        return false;
    }

    public function getAddProductDigitalVariationData(object $request, object|array $product): array
    {
        $digitalFileOptions = $this->getDigitalVariationOptions(request: $request);
        $digitalFileCombinations = $this->getDigitalVariationCombinations(arrays: $digitalFileOptions);

        $digitalFiles = [];
        foreach ($digitalFileCombinations as $combinationKey => $combination) {
            foreach ($combination as $item) {
                $string = $combinationKey . '-' . str_replace(' ', '', $item);
                $uniqueKey = strtolower(str_replace('-', '_', $string));
                $fileItem = $request->file('digital_files.' . $uniqueKey);
                $uploadedFile = '';
                if ($fileItem) {
                    $uploadedFile = $this->fileUpload(dir: 'product/digital-product/', format: $fileItem->getClientOriginalExtension(), file: $fileItem);
                }
                $digitalFiles[] = [
                    'product_id' => $product->id,
                    'variant_key' => $request->input('digital_product_variant_key.' . $uniqueKey),
                    'sku' => $request->input('digital_product_sku.' . $uniqueKey),
                    'price' => currencyConverter(amount: $request->input('digital_product_price.' . $uniqueKey)),
                    'file' => $uploadedFile,
                ];
            }
        }
        return $digitalFiles;
    }

    public function getDigitalVariationCombinationView(object $request, object $product = null): string
    {
        $productName = $request['name'][array_search('en', $request['lang'])];
        $unitPrice = $request['unit_price'];
        $options = $this->getDigitalVariationOptions(request: $request);
        $combinations = $this->getDigitalVariationCombinations(arrays: $options);
        $digitalProductType = $request['digital_product_type'];
        $generateCombination = $this->generateDigitalVariationCombination(request: $request, combinations: $combinations, product: $product);
        return view(Product::DIGITAL_VARIATION_COMBINATION[VIEW], compact('generateCombination', 'unitPrice', 'productName', 'digitalProductType', 'request'))->render();
    }

    public function generatePhysicalVariationCombination(object|array $request, object|array $options, object|array $combinations, object|array|null $product): array
    {
        $productName = $request['name'][array_search('en', $request['lang'])];
        $unitPrice = $request['unit_price'];

        $generateCombination = [];
        $existingType = [];

        if ($product && $product->variation && count(json_decode($product->variation, true)) > 0) {
            foreach (json_decode($product->variation, true) as $digitalVariation) {
                $existingType[] = $digitalVariation['type'];
            }
        }

        $existingType = array_unique($existingType);

        $combinations = array_filter($combinations, function($value) {
            return !empty($value);
        });

        foreach ($combinations as $combination) {
            $type = '';
            foreach ($combination as $combinationKey => $item) {
                if ($combinationKey > 0) {
                    $type .= '-' . str_replace(' ', '', $item);
                } else {
                    if ($request->has('colors_active') && $request->has('colors') && count($request['colors']) > 0) {
                        $color_name = $this->color->where('code', $item)->first()->name;
                        $type .= $color_name;
                    } else {
                        $type .= str_replace(' ', '', $item);
                    }
                }
            }

            $sku = '';
            foreach (explode(' ', $productName) as $value) {
                $sku .= substr($value, 0, 1);
            }
            $sku .= '-' . $type;
            if (in_array($type, $existingType)) {
                if ($product && $product->variation && count(json_decode($product->variation, true)) > 0) {
                    foreach (json_decode($product->variation, true) as $digitalVariation) {
                        if ($digitalVariation['type'] == $type) {
                            $digitalVariation['price'] = $digitalVariation['price'];
                            $digitalVariation['sku'] = str_replace(' ', '', $digitalVariation['sku']);
                            $generateCombination[] = $digitalVariation;
                        }
                    }
                }
            } else {
                $generateCombination[] = [
                    'type' => $type,
                    'price' => currencyConverter(amount: $unitPrice),
                    'sku' => str_replace(' ', '', $sku),
                    'qty' => 1,
                ];
            }
        }

        return $generateCombination;
    }


    public function generateDigitalVariationCombination(object|array $request, object|array $combinations, object|array|null $product): array
    {
        $productName = $request['name'][array_search('en', $request['lang'])];
        $unitPrice = $request['unit_price'];

        $generateCombination = [];
        foreach ($combinations as $combinationKey => $combination) {
            foreach ($combination as $item) {
                $sku = '';
                foreach (explode(' ', $productName) as $value) {
                    $sku .= substr($value, 0, 1);
                }
                $string = $combinationKey . '-' . preg_replace('/\s+/', '-', $item);
                $sku .= '-' . $combinationKey . '-' . str_replace(' ', '', $item);
                $uniqueKey = strtolower(str_replace('-', '_', $string));
                if ($product && $product->digitalVariation && count($product->digitalVariation) > 0) {
                    $productDigitalVariationArray = [];
                    foreach ($product->digitalVariation->toArray() as $variationKey => $digitalVariation) {
                        $productDigitalVariationArray[$digitalVariation['variant_key']] = $digitalVariation;
                    }
                    if (key_exists($string, $productDigitalVariationArray)) {
                        $generateCombination[] = [
                            'product_id' => $product['id'],
                            'unique_key' => $uniqueKey,
                            'variant_key' => $productDigitalVariationArray[$string]['variant_key'],
                            'sku' => $productDigitalVariationArray[$string]['sku'],
                            'price' => $productDigitalVariationArray[$string]['price'],
                            'file' => $productDigitalVariationArray[$string]['file'],
                        ];
                    } else {
                        $generateCombination[] = [
                            'product_id' => $product['id'],
                            'unique_key' => $uniqueKey,
                            'variant_key' => $string,
                            'sku' => $sku,
                            'price' => currencyConverter(amount: $unitPrice),
                            'file' => '',
                        ];
                    }
                } else {
                    $generateCombination[] = [
                        'product_id' => '',
                        'unique_key' => $uniqueKey,
                        'variant_key' => $string,
                        'sku' => $sku,
                        'price' => currencyConverter(amount: $unitPrice),
                        'file' => '',
                    ];
                }
            }
        }
        return $generateCombination;
    }

    public function getDigitalVariationOptions(object $request): array
    {
        $options = [];
        if ($request->has('extensions_type')) {
            foreach ($request->extensions_type as $type) {
                $name = 'extensions_options_' . $type;
                $my_str = implode('|', $request[$name]);
                $optionsArray = [];
                foreach (explode(',', $my_str) as $option) {
                    $optionsArray[] = str_replace('.', '_', removeSpecialCharacters($option));
                }
                $options[$type] = $optionsArray;
            }
        }
        return $options;
    }

    public function getDigitalVariationCombinations(array $arrays): array
    {
        $result = [];
        foreach ($arrays as $arrayKey => $array) {
            foreach ($array as $key => $value) {
                if ($value) {
                    $result[$arrayKey][] = $value;
                }
            }
        }
        return $result;
    }

    public function getProductSEOData(object $request, object|null $product = null, string $action = null): array
    {
        if ($product) {
            if ($request->file('meta_image')) {
                $metaImage = $this->update(dir: 'product/meta/', oldImage: $product['meta_image'], format: 'png', image: $request['meta_image']);
            } elseif (!$request->file('meta_image') && $request->file('image') && $action == 'add') {
                $metaImage = $this->upload(dir: 'product/meta/', format: 'webp', image: $request['image']);
            } else {
                $metaImage = $product?->seoInfo?->image ?? $product['meta_image'];
            }
        } else {
            if ($request->file('meta_image')) {
                $metaImage = $this->upload(dir: 'product/meta/', format: 'webp', image: $request['meta_image']);
            } elseif (!$request->file('meta_image') && $request->file('image') && $action == 'add') {
                $metaImage = $this->upload(dir: 'product/meta/', format: 'webp', image: $request['image']);
            }
        }
        return [
            "product_id" => $product['id'],
            "title" => $request['meta_title'] ?? ($product ? $product['meta_title'] : null),
            "description" => $request['meta_description'] ?? ($product ? $product['meta_description'] : null),
            "index" => $request['meta_index'] == 'index' ? '' : 'noindex',
            "no_follow" => $request['meta_no_follow'] ? 'nofollow' : '',
            "no_image_index" => $request['meta_no_image_index'] ? 'noimageindex' : '',
            "no_archive" => $request['meta_no_archive'] ? 'noarchive' : '',
            "no_snippet" => $request['meta_no_snippet'] ?? 0,
            "max_snippet" => $request['meta_max_snippet'] ?? 0,
            "max_snippet_value" => $request['meta_max_snippet_value'] ?? 0,
            "max_video_preview" => $request['meta_max_video_preview'] ?? 0,
            "max_video_preview_value" => $request['meta_max_video_preview_value'] ?? 0,
            "max_image_preview" => $request['meta_max_image_preview'] ?? 0,
            "max_image_preview_value" => $request['meta_max_image_preview_value'] ?? 0,
            "image" => $metaImage ?? ($product ? $product['meta_image'] : null),
            "created_at" => now(),
            "updated_at" => now(),
        ];
    }

    public function getProductAuthorsInfo(object|array $product): array
    {
        $productAuthorIds = [];
        $productAuthorNames = [];
        $productAuthors = [];
        if ($product?->digitalProductAuthors && count($product?->digitalProductAuthors) > 0) {
            foreach ($product?->digitalProductAuthors as $author) {
                $productAuthorIds[] = $author['author_id'];
                $productAuthors[] = $author?->author;
                if ($author?->author?->name) {
                    $productAuthorNames[] = $author?->author?->name;
                }
            }
        }
        return [
            'ids' => $productAuthorIds,
            'names' => $productAuthorNames,
            'data' => $productAuthors,
        ];
    }

    public function getProductPublishingHouseInfo(object|array $product): array
    {
        $productPublishingHouseIds = [];
        $productPublishingHouseNames = [];
        $productPublishingHouses = [];
        if ($product?->digitalProductPublishingHouse && count($product?->digitalProductPublishingHouse) > 0) {
            foreach ($product?->digitalProductPublishingHouse as $publishingHouse) {
                $productPublishingHouseIds[] = $publishingHouse['publishing_house_id'];
                $productPublishingHouses[] = $publishingHouse?->publishingHouse;
                if ($publishingHouse?->publishingHouse?->name) {
                    $productPublishingHouseNames[] = $publishingHouse?->publishingHouse?->name;
                }
            }
        }
        return [
            'ids' => $productPublishingHouseIds,
            'names' => $productPublishingHouseNames,
            'data' => $productPublishingHouses,
        ];
    }

    public function sendRestockProductNotification(object|array $restockRequest, string $type = null): void
    {
        // Send Notification to customer
        $data = [
            'topic' => getRestockProductFCMTopic(restockRequest: $restockRequest),
            'title' => $restockRequest?->product?->name,
            'product_id' => $restockRequest?->product?->id,
            'slug' => $restockRequest?->product?->slug,
            'description' => $type == 'restocked' ? translate('This_product_has_restocked') : translate('Your_requested_restock_product_has_been_updated'),
            'image' => getStorageImages(path: $restockRequest?->product?->thumbnail_full_url ?? '', type: 'product'),
            'route' => route('product', $restockRequest?->product?->slug),
            'type' => 'product_restock_update',
            'status' => $type == 'restocked' ? 'product_restocked' : 'product_update',
        ];
        event(new RestockProductNotificationEvent(data: $data));
    }

    public function validateStockClearanceProductDiscount($stockClearanceProduct): bool
    {
        if ($stockClearanceProduct && $stockClearanceProduct['discount_type'] == 'flat' && $stockClearanceProduct?->setup && $stockClearanceProduct?->setup?->discount_type == 'product_wise') {
            $minimumPrice = $stockClearanceProduct?->product?->unit_price;
            foreach ((json_decode($stockClearanceProduct?->product?->variation, true) ?? []) as $variation) {
                if ($variation['price'] < $minimumPrice) {
                    $minimumPrice = $variation['price'];
                }
            }

            if ($minimumPrice < $stockClearanceProduct['discount_amount']) {
                return false;
            }
        }
        return true;
    }
}
