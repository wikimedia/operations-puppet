class apache::mod::uwsgi {
  include apache

  package { 'mod_uwsgi_package':
    ensure  => installed,
    name    => $apache::params::mod_uwsgi_package,
    require => Package['httpd'];
  }

  a2mod { 'uwsgi': ensure => present; }
}
