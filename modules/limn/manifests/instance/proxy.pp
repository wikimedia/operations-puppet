# == Define limn::instance::proxy
# Sets up an apache mod_rewrite proxy for proxying to a Limn instance.
# Static files in $document_root will be served by apache.
# This define depends on the apache puppet module.
#
# == Parameters:
# $port           - Apache port to Listen on.  Default: 80.
# $limn_host      - Hostname or IP of Limn instnace.  Default: 127.0.0.1
# $limn_port      - Port of Limn instance. Default: 8081
# $document_root  - Path to Apache document root.   This should be the limn::instance $var_directory.  Default: /usr/local/limn/var.
# $server_name    - Named VirtualHost.    Default: "$name.$domain"
# $server_aliases - Server name aliases.  Default: none.
#
define limn::instance::proxy (
  $port            = 80,
  $limn_host       = '127.0.0.1',
  $limn_port       = '8081',
  $document_root   = '/usr/local/share/limn/var',
  $server_name     = "${name}.${::domain}",
  $server_aliases  = '')
{
  # need apache and mod_rewrite
  class { 'apache':
    serveradmin  => $server_admin,
    default_mods => true,
  }
  apache::mod { 'rewrite': }

  # Configure the Apache Limn instance proxy VirtualHost.
  $priority      = 10
  file { "${priority}-limn-${name}.conf":
    path    => "${apache::params::vdir}/${priority}-limn-${name}.conf",
    content => template('limn/vhost-limn-proxy.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    require => [Package['httpd'], Apache::Mod['rewrite']],
    notify  => Service['httpd'],
  }
}
