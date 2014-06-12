
class { 'cxserver':
    base_path => '/tmp/cxserver/',
    node_path => '/tmp/cxserver/node_modules',
    log_dir   => '/var/log/cxserver',
    log_file  => '/var/log/cxserver/main.log',
}
