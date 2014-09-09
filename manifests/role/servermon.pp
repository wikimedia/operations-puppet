# Class: role::servermon
#
# This class installs all the servermon related parts as WMF requires it
#
# Actions:
#       Deploy servermon
#       Install apache, gunicorn, configure reverse proxy to gunicorn, LDAP
#       authentication
#
# Requires:
#
# Sample Usage:
#       include role::servermon
#
class role::servermon {
    include ::apache
    include ::apache::mod::proxy_http
    include ::apache::mod::proxy
    include ::apache::mod::rewrite
    include ::apache::mod::ssl
    include ::apache::mod::auth_basic
    include ::apache::mod::authnz_ldap

    include passwords::servermon
    $db_user = $passwords::servermon::db_user
    $db_password = $passwords::servermon::db_password
    $secret_key = $passwords::servermon::secret_key

    # Used for apache LDAP auth
    include passwords::ldap::wmf_cluster
    $proxypass = $passwords::ldap::wmf_cluster::proxypass

    $ssl_settings = ssl_ciphersuite('apache-2.2', 'compat')

    class { '::servermon':
        ensure      => 'present',
        directory   => '/srv/deployment/servermon/servermon',
        db_engine   => 'mysql',
        db_name     => 'puppet',
        db_user     => $db_user,
        db_password => $db_password,
        secret_key  => $secret_key,
        db_host     => 'm1-master.eqiad.wmnet',
        admins      => '("Ops Team", "ops@lists.wikimedia.org")',
    }

    deployment::target {'servermon': }

    apache::site { 'servermon.wikimedia.org':
        content => template('apache/sites/servermon.wikimedia.org.erb'),
    }
}
