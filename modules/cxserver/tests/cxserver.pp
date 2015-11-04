class { 'cxserver':
    base_path => '/tmp/cxserver/',
    node_path => '/tmp/cxserver/node_modules',
    conf_path => '/tmp/cxserver/config.js',
    log_dir   => '/var/log/cxserver',
    restbase  => 'http://127.0.0.1',
    apertium  => 'http://apertium-beta.wmflabs.org',
}
