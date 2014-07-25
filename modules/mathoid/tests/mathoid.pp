class { 'mathoid':
    base_path => '/tmp/mathoid/',
    node_path => '/tmp/mathoid/node_modules',
    conf_path => '/tmp/mathoid/config.js',
    log_dir   => '/var/log/mathoid',
    parsoid   => 'http://127.0.0.1',
}
