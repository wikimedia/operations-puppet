# Class: profile::netbox
#
# This profile installs all the Netbox related parts as WMF requires it
#
# Actions:
#       Deploy Netbox
#       Install apache, gunicorn, configure reverse proxy to gunicorn, LDAP
#       authentication
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
# lint:endignore

  include passwords::netbox
  $db_password = $passwords::netbox::db_password   #### NOT DEFINED YET
  $secret_key = $passwords::netbox::secret_key     #### NOT DEFINED YET

  # Used for LDAP auth
  include passwords::ldap::wmf_cluster
  $proxypass = $passwords::ldap::wmf_cluster::proxypass

  # If new install, postgres user needs to be manually added, see:
  # http://netbox.readthedocs.io/en/stable/installation/postgresql/#database-creation
  require_package('postgresql', 'libpq-dev')


  scap::target { 'netbox/deploy':
      deploy_user => 'deploy-librenms',
  }

  class { '::netbox':
      directory     => '/srv/deployment/netbox/netbox',
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
