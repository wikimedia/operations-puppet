class role::analytics::sqoop {
    $cdh_module_name = $::realm ? {
        'production' => 'cdh4',
        'labs'       => 'cdh',
    }
    class { "${cdh_module_name}::sqoop": }
}