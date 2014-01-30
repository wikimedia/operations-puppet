# vim:sw=4 ts=4 sts=4 et:

# == Class: role::kibana
#
# Provisions Kibana
#
class role::kibana {
    include ::apache
    include ::passwords::ldap::production

    $hostname      = 'logstash.wikimedia.org'
    $deploy_dir    = '/srv/deployment/kibana/kibana'
    $es_host       = '127.0.0.1'
    $es_port       = 9200
    $ldap_authurl  = 'ldaps://virt1000.wikimedia.org virt0.wikimedia.org/ou=people,dc=wikimedia,dc=org?cn'
    $ldap_bindpass = $passwords::ldap::production::proxypass
    $ldap_binddn   = 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org'
    $ldap_group    = 'cn=wmf,ou=groups,dc=wikimedia,dc=org'
    $auth_realm    = 'WMF Labs (use wiki login name not shell)'
    $serveradmin   = 'root@wikimedia.org'

    class { '::kibana':
        default_route => '/dashboard/elasticsearch/default',
    }

    apache::mod { [
        'alias',
        'authnz_ldap',
        'headers',
        'proxy',
        'proxy_http',
        'rewrite',
    ]: }

    file { "/etc/apache2/sites-available/${hostname}":
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('kibana/apache.conf.erb'),
        require => Package['httpd'],
    }

    file { "/etc/apache2/sites-enabled/${hostname}":
        ensure  => link,
        target  => "/etc/apache2/sites-available/${hostname}",
        require => File["/etc/apache2/sites-available/${hostname}"],
        notify  => Service['httpd'],
    }
}
