# RT - Request Tracker
# 
#  This will create a server running RT on lighttpd.
#
#  It's used in production but should function in labs
#  as well.
class misc::rt::server ( $site = 'rt.wikimedia.org', $datadir = '/var/lib/mysql' ) {
  system_role { 'misc::rt::server': description => 'RT server' }

  package { [ 'request-tracker3.8', 'rt3.8-db-mysql', 'rt3.8-clients', 'libcgi-fast-perl', 'lighttpd',
    'libdbd-pg-perl' ]:
    ensure => latest;
  }

  class { 'generic::mysql::server':
    version => $::lsbdistrelease ? {
      '12.04' => '5.5',
      default => false,
    },
    datadir => $datadir;
  }

  $rtconf = '# This file is for the command-line client, /usr/bin/rt.\n\nserver http://localhost/rt\n'

  file {
    '/etc/lighttpd/conf-available/10-rt.conf':
      ensure  => present,
      content => template('rt/10-rt.lighttpd.conf.erb');
    '/var/run/fastcgi':
      ensure => directory,
      owner  => 'www-data',
      group  => 'www-data',
      mode   => '0750';
    '/etc/request-tracker3.8/RT_SiteConfig.d/50-debconf':
      source => 'puppet:///files/rt/50-debconf',
      notify => Exec['update-rt-siteconfig'];
    '/etc/request-tracker3.8/RT_SiteConfig.d/80-wikimedia':
      source => 'puppet:///files/rt/80-wikimedia',
      notify => Exec['update-rt-siteconfig'];
    '/etc/request-tracker3.8/RT_SiteConfig.pm':
      owner => 'root',
      group => 'www-data',
      mode  => '0440';
    '/etc/request-tracker3.8/rt.conf':
      require => Package['request-tracker3.8'],
      content => $rtconf;
    '/etc/cron.d/mkdir-var-run-fastcgi':
      content => '@reboot root  mkdir /var/run/fastcgi';
  }

  if ( $realm == "labs" ) {
    # If we're a new labs install, set up the RT database.
    exec { 'rt-db-initialize':
      command => "/bin/echo '' | /usr/sbin/rt-setup-database --action init --dba root --prompt-for-dba-password",
      require => [ package[ 'request-tracker3.8', 'rt3.8-db-mysql', 'rt3.8-clients', 'libcgi-fast-perl', 'lighttpd',
        'libdbd-pg-perl' ] ],
      unless  => '/usr/bin/mysqlshow rtdb';
    }
  }

  exec { 'update-rt-siteconfig':
    command     => '/usr/sbin/update-rt-siteconfig-3.8',
    subscribe => file[ "/etc/request-tracker3.8/RT_SiteConfig.d/50-debconf",
                       "/etc/request-tracker3.8/RT_SiteConfig.d/80-wikimedia" ],
    require => package[ 'request-tracker3.8', 'rt3.8-db-mysql', 'rt3.8-clients', 'libcgi-fast-perl' ],
    refreshonly => true,
    notify      => Service[lighttpd];
  }

  lighttpd_config { '10-rt':
    require => [ package[ 'request-tracker3.8', 'rt3.8-db-mysql', 'rt3.8-clients', 'libcgi-fast-perl', 'lighttpd' ],
      File[ '/etc/lighttpd/conf-available/10-rt.conf', '/var/run/fastcgi', '/etc/request-tracker3.8/RT_SiteConfig.d/50-debconf',
        '/etc/request-tracker3.8/RT_SiteConfig.d/80-wikimedia', '/etc/cron.d/mkdir-var-run-fastcgi', '/etc/request-tracker3.8/rt.conf' ] ],
    notify      => Service[lighttpd];
  }

  service { 'lighttpd':
    ensure => running;
  }
}

