<?php

return [
    'models' => [
        'addon_choice' => \Vtlabs\Ecommerce\Models\AddonChoice::class,
        'addon_group' => \Vtlabs\Ecommerce\Models\AddonGroup::class,
        'address' => \Vtlabs\Ecommerce\Models\Address::class,
        'order' => \Vtlabs\Ecommerce\Models\Order::class,
        'order_delivery' => \Vtlabs\Ecommerce\Models\OrderDelivery::class,
        'order_product' => \Vtlabs\Ecommerce\Models\OrderProduct::class,
        'order_product_addon' => \Vtlabs\Ecommerce\Models\OrderProductAddon::class,
        'product' => \Vtlabs\Ecommerce\Models\Product::class,
        'user' => config('auth.models.user'),
        'vendor' => \Vtlabs\Ecommerce\Models\Vendor::class,
        'vendor_product' => \Vtlabs\Ecommerce\Models\VendorProduct::class,
        'delivery_profile' => \Vtlabs\Ecommerce\Models\DeliveryProfile::class,
        'coupon' => \Vtlabs\Ecommerce\Models\Coupon::class,
        'coupon_user' => \Vtlabs\Ecommerce\Models\Coupon::class,
    ],

    'resources' => [
        'admin' => [
            'vendor' => \Vtlabs\Ecommerce\Http\Resources\Admin\VendorAdminResource::class,
            'product' => \Vtlabs\Ecommerce\Http\Resources\Admin\ProductAdminResource::class,
            'vendor_product' => \Vtlabs\Ecommerce\Http\Resources\Admin\VendorProductAdminResource::class,
            'addon_group' => \Vtlabs\Ecommerce\Http\Resources\Admin\AddonGroupAdminResource::class,
            'addon_choice' => \Vtlabs\Ecommerce\Http\Resources\Admin\AddonChoiceAdminResource::class,
        ],
        'vendor' => \Vtlabs\Ecommerce\Http\Resources\VendorResource::class,
        'product' => \Vtlabs\Ecommerce\Http\Resources\ProductResource::class,
        'vendor_product' => \Vtlabs\Ecommerce\Http\Resources\VendorProductResource::class,
    ],

    'vendor' => [
        'status_list' => ['open', 'close'],
        'status_default' => 'open',
        'verify_default' => true
    ],

    'order' => [
        'status_list' => ['new', 'pending', 'cancelled', 'rejected', 'refund', 'hold', 'failed', 'accepted', 'preparing', 'prepared', 'dispatched', 'intransit', 'complete'],
        'status_default' => 'new',
        'verify_default' => true
    ],

    'delivery_profile' => [
        'verify_default' => true
    ],

    'order_delivery' => [
        'status_list' => ['new', 'pending', 'allotted', 'pickup', 'started', 'cancelled', 'complete'],
        'status_default' => 'new'
    ],

    'delivery_order_request' => [
        'status_list' => ['pending', 'accepted', 'rejected'],
        'status_default' => 'pending'
    ],

    'product' => [
        'status_list' => ['pending', 'rejected', 'approved'],
        'status_default' => 'approved'
    ]
];