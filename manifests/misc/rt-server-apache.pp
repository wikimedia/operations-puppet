# RT - Request Tracker
# 
#  This will create a server running RT with apache.
#
class misc::rt-apache::server ( $site = 'rt.wikmedia.org', $datadir = '/var/lib/mysql' ) {
  system_role { 'misc::rt-apache::server': description => 'RT server with Apache' }

  package { [ 'request-tracker4', 'rt4-db-mysql', 'rt4-clients', 'libdbd-pg-perl' ]:
    ensure => latest;
  }

  include apache

  $rtconf = '# This file is for the command-line client, /usr/bin/rt.\n\nserver http://localhost/rt\n'

  file {
    '/etc/request-tracker4/RT_SiteConfig.d/50-debconf':
      require => package['request-tracker4'],
      source => 'puppet:///files/rt/50-debconf',
      notify => Exec['update-rt-siteconfig'];
    '/etc/request-tracker4/RT_SiteConfig.d/80-wikimedia':
      require => package['request-tracker4'],
      source => 'puppet:///files/rt/80-wikimedia',
      notify => Exec['update-rt-siteconfig'];
    '/etc/request-tracker4/RT_SiteConfig.pm':
      require => package['request-tracker4'],
      owner => 'root',
      group => 'www-data',
      mode  => '0440';
    '/etc/request-tracker4/rt.conf':
      require => Package['request-tracker4'],
      content => $rtconf;
  }

  exec { 'update-rt-siteconfig':
    command     => '/usr/sbin/update-rt-siteconfig-4',
    subscribe => file[ "/etc/request-tracker4/RT_SiteConfig.d/50-debconf",
                       "/etc/request-tracker4/RT_SiteConfig.d/80-wikimedia" ],
    require => package[ 'request-tracker4', 'rt4-db-mysql', 'rt4-clients' ],
    refreshonly => true,
    notify      => Service[httpd];
  }

  file { '/etc/apache2/sites-available/rt4':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('rt/rt4.apache.erb'),
  }

  apache_module { 'perl':
    name => 'perl',
  }

  apache_site { 'rt4':
    name => 'rt4'
  }

}
