class { 'cxserver':
    base_path => '/tmp/cxserver/',
    node_path => '/tmp/cxserver/node_modules',
    conf_path => '/tmp/cxserver/config.js',
    log_dir   => '/var/log/cxserver',
    parsoid   => 'http://127.0.0.1',
}
