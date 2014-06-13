# Class: apache::params
#
# This class manages Apache parameters
#
# Parameters:
# - The $user that Apache runs as
# - The $group that Apache runs as
# - The $apache_name is the name of the package and service on the relevant
#   distribution
# - The $php_package is the name of the package that provided PHP
# - The $ssl_package is the name of the Apache SSL package
# - The $apache_dev is the name of the Apache development libraries package
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class apache::params {

  $ssl           = true
  $template      = 'apache/vhost-default.conf.erb'
  $priority      = '25'
  $servername    = ''
  $serveraliases = ''
  $auth          = false
  $redirect_ssl  = false
  $ssl_path      = '/etc/ssl'
  $options       = 'Indexes FollowSymLinks MultiViews'
  $override      = 'None'
  $vhost_name    = '*'

  $user                  = 'www-data'
  $group                 = 'www-data'
  $apache_name           = 'apache2'
  $php_package           = 'libapache2-mod-php5'
  $mod_passenger_package = 'libapache2-mod-passenger'
  $mod_python_package    = 'libapache2-mod-python'
  $mod_wsgi_package      = 'libapache2-mod-wsgi'
  $mod_uwsgi_package     = 'libapache2-mod-uwsgi'
  $mod_auth_kerb_package = 'libapache2-mod-auth-kerb'
  $apache_dev            = ['libaprutil1-dev', 'libapr1-dev', 'apache2-prefork-dev']
  $vdir                  = '/etc/apache2/sites-enabled'
  $proxy_modules         = ['proxy', 'proxy_http']
  $mod_packages          = {
    'dev'        => ['libaprutil1-dev', 'libapr1-dev', 'apache2-prefork-dev'],
    'fcgid'      => 'libapache2-mod-fcgid',
    'passenger'  => 'libapache2-mod-passenger',
    'perl'       => 'libapache2-mod-perl2',
    'php5'       => 'libapache2-mod-php5',
    'proxy_html' => 'libapache2-mod-proxy-html',
    'python'     => 'libapache2-mod-python',
    'wsgi'       => 'libapache2-mod-wsgi',
  }
  $mod_libs              = {}
  $mod_identifiers       = {}
}
