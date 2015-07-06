# vim:sw=4 ts=4 sts=4 et:

# == Class: role::kibana
#
# Provisions Kibana
#
class role::kibana {
    include ::apache

    if ($::realm == 'labs') {
        include ::apache::mod::authz_groupfile
        include ::apache::mod::authz_user

        if ($::hostname =~ /^deployment-/) {
            # Beta
            $hostname    = 'logstash.beta.wmflabs.org'
            $deploy_dir  = '/srv/deployment/kibana/kibana'
            $auth_realm  = 'Logstash (ssh deployment-bastion.eqiad.wmflabs sudo cat /root/secrets.txt)'
            $auth_file   = '/etc/logstash/htpasswd'
            $require_ssl = true
        } else {
            # Regular labs instance
            $hostname = $::kibana_hostname ? {
                undef   => $::hostname,
                default => $::kibana_hostname,
            }
            $deploy_dir = $::kibana_deploydir ? {
                undef   => '/srv/deployment/kibana/kibana',
                default => $::kibana_deploydir,
            }
            $auth_realm = $::kibana_authrealm ? {
                undef   => 'Logstash',
                default => $::kibana_authrealm,
            }
            $auth_file = $::kibana_authfile ? {
                undef   => '/etc/logstash/htpasswd',
                default => $::kibana_authfile,
            }
            $require_ssl = false
        }
        $serveradmin = "root@${hostname}"
        $apache_auth   = template('kibana/apache-auth-local.erb')
    } else {
        # Production
        include ::apache::mod::authnz_ldap
        include ::passwords::ldap::production

        $hostname      = 'logstash.wikimedia.org'
        $deploy_dir    = '/srv/deployment/kibana/kibana'
        $serveradmin   = 'noc@wikimedia.org'
        $require_ssl   = true

        $ldap_authurl  = 'ldaps://ldap-eqiad.wikimedia.org ldap-codfw.wikimedia.org/ou=people,dc=wikimedia,dc=org?cn'
        $ldap_bindpass = $passwords::ldap::production::proxypass
        $ldap_binddn   = 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org'
        $ldap_groups   = [
            'cn=ops,ou=groups,dc=wikimedia,dc=org',
            'cn=nda,ou=groups,dc=wikimedia,dc=org',
            'cn=wmf,ou=groups,dc=wikimedia,dc=org',
        ]
        $auth_realm    = 'WMF Labs (use wiki login name not shell) - nda/ops/wmf'
        $apache_auth   = template('kibana/apache-auth-ldap.erb')
    }
    $es_host = '127.0.0.1'
    $es_port = 9200

    class { '::kibana':
        default_route => '/dashboard/elasticsearch/default',
    }

    include ::apache::mod::alias
    include ::apache::mod::headers
    include ::apache::mod::proxy
    include ::apache::mod::proxy_http
    include ::apache::mod::rewrite

    apache::site { $hostname:
        content => template('kibana/apache.conf.erb'),
    }
}
