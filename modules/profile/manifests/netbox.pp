# Class: profile::netbox
#
# This profile installs all the Netbox related parts as WMF requires it
#
# Actions:
#       Deploy Netbox
#       Install apache, gunicorn, configure reverse proxy to gunicorn, LDAP
#       authentication and database
#
# Requires:
#
# Sample Usage:
#       include profile::netbox
#
class profile::netbox ($active_server = hiera('netmon_server', 'netmon1002.wikimedia.org')) {

# lint:ignore:wmf_styleguide
  include ::apache
  include ::apache::mod::headers
  include ::apache::mod::proxy_http
  include ::apache::mod::proxy
  include ::apache::mod::rewrite
  include ::apache::mod::ssl
  include ::apache::mod::wsgi
# lint:endignore

  include passwords::netbox
  $db_password = $passwords::netbox::db_password
  $secret_key = $passwords::netbox::secret_key
  $replication_pass = $passwords::netbox::replication_password

  # Used for LDAP auth
  include passwords::ldap::wmf_cluster
  $proxypass = $passwords::ldap::wmf_cluster::proxypass

  # Define master postgres server
  $master = 'netmon1002.wikimedia.org'

  # Inspired by modules/puppetmaster/manifests/puppetdb/database.pp
  if $master == $::fqdn {
      # We do this for the require in postgres::db
      $require_class = 'postgresql::master'
      class { '::postgresql::master':
          includes => ['tuning.conf'],
          root_dir => '/srv/postgres',
          use_ssl  => true,
      }
      $on_master = true
  } else {
      $require_class = 'postgresql::slave'
      class { '::postgresql::slave':
          includes         => ['tuning.conf'],
          master_server    => $master,
          root_dir         => '/srv/postgres',
          replication_pass => $replication_pass,
          use_ssl          => true,
      }
      $on_master = false
  }

    postgresql::user { 'replication@netmon2001':
        ensure    => present,
        user      => 'replication',
        database  => 'all',
        password  => $replication_pass,
        cidr      => '208.80.153.110/32',
        pgversion => '9.4',
        master    => $on_master,
        attrs     => 'REPLICATION',
    }
    postgresql::user { 'netbox@netmon2001':
        ensure    => present,
        user      => 'netbox',
        database  => 'netbox',
        password  => $db_password,
        cidr      => '208.80.153.110/32',
        pgversion => '9.4',
        master    => $on_master,
    }
  # Create the netbox user for localhost
  # This works on every server and is used for read-only db lookups
  postgresql::user { 'netbox@localhost':
      ensure    => present,
      user      => 'netbox',
      database  => 'netbox',
      password  => $db_password,
      cidr      => "${::ipaddress}/32",
      pgversion => '9.4',
      master    => $on_master,
  }

  # Create the database
  postgresql::db { 'netbox':
      owner   => 'netbox',
      require => Class[$require_class],
  }



  class { '::netbox':
      directory     => '/srv/deployment/netbox/deploy/netbox',
      db_password   => $db_password,
      secret_key    => $secret_key,
      ldap_password => $proxypass,
      admins        => '("Ops Team", "ops@lists.wikimedia.org")',
  }
  $ssl_settings = ssl_ciphersuite('apache', 'mid', true)


  apache::site { 'netbox.wikimedia.org':
      content => template('profile/netbox/netbox.wikimedia.org.erb'),
  }

  letsencrypt::cert::integrated { 'netbox':
      subjects   => 'netbox.wikimedia.org',
      puppet_svc => 'apache2',
      system_svc => 'apache2',
      require    => Class['apache::mod::ssl'],
  }
  if $active_server == $::fqdn {
      $monitoring_ensure = 'present'
  } else {
      $monitoring_ensure = 'absent'
  }

  monitoring::service { 'https':
      ensure        => $monitoring_ensure,
      description   => 'HTTPS',
      check_command => 'check_ssl_http_letsencrypt!netbox.wikimedia.org',
  }

  monitoring::service { 'librenms':
      ensure        => $monitoring_ensure,
      description   => 'LibreNMS HTTPS',
      check_command => 'check_https_url!netbox.wikimedia.org!https://netbox.wikimedia.org',
  }


}
