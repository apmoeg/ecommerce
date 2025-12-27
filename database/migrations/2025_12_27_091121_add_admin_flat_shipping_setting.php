<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use App\Models\BusinessSetting;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Add admin flat shipping rate setting
        BusinessSetting::updateOrCreate(
            ['type' => 'admin_flat_shipping_rate'],
            ['value' => '0']
        );
        
        // Add admin flat shipping status setting (enabled/disabled)
        BusinessSetting::updateOrCreate(
            ['type' => 'admin_flat_shipping_status'],
            ['value' => '1']
        );
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        BusinessSetting::where('type', 'admin_flat_shipping_rate')->delete();
        BusinessSetting::where('type', 'admin_flat_shipping_status')->delete();
    }
};
