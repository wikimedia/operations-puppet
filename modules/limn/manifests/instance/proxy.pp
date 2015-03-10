# == Define limn::instance::proxy
# Sets up an apache mod_rewrite proxy for proxying to a Limn instance.
# Static files in $document_root will be served by apache.
#
# NOTE: You must install apache yourself.
# A Service and Package named 'apache2' must be defined.
# You must also make sure mod_rewrite, mod_proxy, and mod_proxy_http
# are enabled.
#
# == Parameters:
# $port           - Apache port to Listen on.  Default: 80.
# $limn_host      - Hostname or IP of Limn instnace.  Default: 127.0.0.1
# $limn_port      - Port of Limn instance. Default: 8081
# $document_root  - Path to Apache document root.   This should be the limn::instance $var_directory.  Default: /usr/local/share/limn/var.
# $server_name    - Named VirtualHost.    Default: "$name.$domain"
# $server_aliases - Server name aliases.  Default: none.
# $site_template  - Template for Apache conf.  Default: limn/vhost-limn-proxy.conf.erb.
#
define limn::instance::proxy (
    $port            = '80',
    $limn_host       = '127.0.0.1',
    $limn_port       = '8081',
    $document_root   = '/usr/local/share/limn/var',
    $server_name     = "${name}.${::domain}",
    $server_aliases  = '',
    $site_template   = 'limn/vhost-limn-proxy.conf.erb'),
){
    # Configure the Apache Limn instance proxy VirtualHost.
    $priority = 10
    file { "${priority}-limn-${name}.conf":
        path    => "/etc/apache2/sites-enabled/${priority}-limn-${name}.conf",
        content => template($site_template),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['apache2'],
        notify  => Service['apache2'],
    }
}
