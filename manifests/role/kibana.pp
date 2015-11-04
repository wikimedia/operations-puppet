# vim:sw=4 ts=4 sts=4 et:

# == Class: role::kibana
#
# Provisions Kibana
#
# == Parameters:
# - $vhost: Apache vhost name
# - $serveradmin: Email address for contacting server administrator
# - $auth_type: Vhost auth type. One of ldap, local, none
# - $es_host: Elasticsearch host to proxy to
# - $es_port: Elasticsearch port to proxy to
# - $require_ssl: Require SSL connection to vhost?
# - $auth_realm: HTTP basic auth realm description
# - $auth_file: Path to htpasswd file for $auth_type == 'local'
# - $ldap_authurl: AuthLDAPURL for $auth_type == 'ldap'
# - $ldap_binddn: AuthLDAPBindDN for $auth_type == 'ldap'
# - $ldap_groups: List of ldap-group names for $auth_type == 'ldap'
#
class role::kibana (
    $vhost,
    $serveradmin,
    $auth_type,
    $es_host       = '127.0.0.1',
    $es_port       = 9200,
    $require_ssl   = true,
    $auth_realm    = undef,
    $auth_file     = undef,
    $ldap_authurl  = undef,
    $ldap_binddn   = undef,
    $ldap_groups   = [],
) {
    include ::apache
    include ::apache::mod::alias
    include ::apache::mod::headers
    include ::apache::mod::proxy
    include ::apache::mod::proxy_http
    include ::apache::mod::rewrite
    include base::firewall

    # Directory trebuchet puts Kibana files in
    $deploy_dir = '/srv/deployment/kibana/kibana'

    if $auth_type == 'ldap' {
        include ::apache::mod::authnz_ldap
        include ::passwords::ldap::production

        # FIXME: move this into hiera config
        $ldap_bindpass = $passwords::ldap::production::proxypass

    } elsif $auth_type == 'local' {
        include ::apache::mod::authz_groupfile
        include ::apache::mod::authz_user

    } elsif $auth_type != 'none' {
        fail('role::kibana::auth_type must be one of ldap, local, none')
    }

    $apache_auth = template("kibana/apache-auth-${auth_type}.erb")

    class { '::kibana':
        default_route => '/dashboard/elasticsearch/default',
    }

    ferm::service { 'kibana_frontend':
        proto  => 'tcp',
        port   => 80,
        notrack => true,
        srange => '$INTERNAL',
    }

    apache::site { $vhost:
        content => template('kibana/apache.conf.erb'),
    }
}
