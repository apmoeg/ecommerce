<?php

namespace App\Enums\ViewPaths\Admin;

enum Color
{
    const LIST = [
        URI => 'list',
        VIEW => 'admin-views.color.list'
    ];
    const ADD = [
        URI => 'add-new',
        VIEW => 'admin-views.color.add'
    ];
    const UPDATE = [
        URI => 'edit',
        VIEW => 'admin-views.color.update' //<-- CHANGE HERE!
    ];
    const DELETE = [
        URI => 'delete',
        VIEW => ''
    ];
    const STATUS = [
        URI => 'status-update',
        VIEW => ''
    ];
}
