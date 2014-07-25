class { 'mathoid':
    base_path => '/tmp/mathoid/',
    node_path => '/tmp/mathoid/node_modules',
    conf_path => '/tmp/mathoid/config.config.json',
    log_dir   => '/var/log/mathoid',
    port   => '10042',
}
