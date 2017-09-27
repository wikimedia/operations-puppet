class dumps::web::nginx_logrot {
    logrotate::conf { 'nginx':
        ensure => present,
        source => 'puppet:///modules/dumps/web/nginx_logrotate.conf',
    }
}
