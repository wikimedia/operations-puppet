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
#       role(servermon)
#
# filtertags: labs-project-servermon
class role::servermon {

    class { '::httpd':
        modules => ['proxy',
                    'proxy_http',
                    'rewrite',
                    'ssl',
                    'auth_basic',
                    'authnz_ldap',
                    'headers',
                    ],
    }

    system::role { 'servermon': description => 'Servermon server' }

    include passwords::servermon
    $db_user = $passwords::servermon::db_user
    $db_password = $passwords::servermon::db_password
    $secret_key = $passwords::servermon::secret_key

    # Used for apache LDAP auth
    include passwords::ldap::wmf_cluster
    $proxypass = $passwords::ldap::wmf_cluster::proxypass

    class { '::servermon':
        ensure      => 'present',
        directory   => '/srv/deployment/servermon/servermon/servermon',
        db_engine   => 'mysql',
        db_name     => 'puppet',
        db_user     => $db_user,
        db_password => $db_password,
        secret_key  => $secret_key,
        db_host     => 'm1-master.eqiad.wmnet',
        admins      => '("Ops Team", "ops@lists.wikimedia.org")',
    }

    httpd::site { 'servermon.wikimedia.org':
        content => template('role/servermon/servermon.wikimedia.org.erb'),
    }

    ferm::service { 'servermon-http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHE_MISC',
    }

}
