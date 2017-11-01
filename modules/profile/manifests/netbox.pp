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

class profile::netbox {
  include ::apache
  include ::apache::mod::proxy_http
  include ::apache::mod::proxy


  include passwords::netbox
  $db_password = $passwords::netbox::db_password   #### NOT DEFINED YET
  $secret_key = $passwords::netbox::secret_key     #### NOT DEFINED YET

  # Used for LDAP auth
  include passwords::ldap::wmf_cluster
  $proxypass = $passwords::ldap::wmf_cluster::proxypass

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

  apache::site { 'netbox.wikimedia.org':
      content => template('role/netbox/netbox.wikimedia.org.erb'),
  }

}
