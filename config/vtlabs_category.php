<?php

return [
    'models' => [
        'category' => \Vtlabs\Category\Models\Category::class,
    ],
    'resources' => [
        'admin' => [
            'category' => \Vtlabs\Category\Http\Resources\Admin\CategoryResource::class,
        ],
        'category' => \Vtlabs\Category\Http\Resources\CategoryResource::class,
    ],
    'tables' => [
        'category' => 'categories',
    ],
    'images' => [
        'thumb' => 50
    ]
];