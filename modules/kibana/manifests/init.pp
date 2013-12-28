# vim:sw=4 ts=4 sts=4 et:

# = Class: kibana
#
# This class installs/configures/manages the Kibana application.
#
# == Parameters:
# - $hostname: Hostname for apache vhost.
# - $deploy_dir: Directory application is deployed to. Default
#       '/srv/deployment/kibana/kibana'.
# - $es_host: Elasticsearch server. Default '127.0.0.1'.
# - $es_port: Elasticsearch server port. Default 9200.
# - $ldap_authurl: Url for LDAP server
# - $ldap_binddn: DN for binding to LDAP server
# - $ldap_group: LDAP group to require for authenication
# - $auth_realm: HTTP basic auth realm
# - $serveradmin: Administrative contact email address
#
# == Sample usage:
#
#   class { 'kibana':
#       hostname     => 'kibana.example.com',
#       ldap_authurl => 'ldaps://ldap.example.com/ou=people,dc=example,dc=com?cn',
#       ldap_binddn  => 'cn=binduser,ou=people,dc=example,dc=com',
#       ldap_group   => 'cn=kibana,ou=groups,dc=example,dc=com',
#       auth_realm   => 'Kibana',
#   }
#
class kibana(
    $hostname     = undef,
    $deploy_dir   = '/srv/deployment/kibana/kibana',
    $es_host      = '127.0.0.1',
    $es_port      = 9200,
    $ldap_authurl = undef,
    $ldap_binddn  = undef,
    $ldap_group   = undef,
    $auth_realm   = undef,
    $serveradmin  = 'root@wikimedia.org',
) {

    include ::apache
    include ::passwords::ldap::production

    $proxypass = $passwords::ldap::production::proxypass

    # Trebuchet deployment
    deployment::target { 'kibana': }

    apache::mod { [
        'authnz_ldap',
        'proxy',
        'proxy_http',
        'alias',
    ]: }

    file { "/etc/apache2/sites-available/${hostname}":
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('kibana/apache.conf.erb');
        require => Package['httpd'],
    }

    file { "/etc/apache2/sites-enabled/${hostname}":
        ensure  => link,
        target  => "/etc/apache2/sites-available/${hostname}",
        require => File["/etc/apache2/sites-available/${hostname}"],
        notify  => Service['httpd'],
    }

    file { '/etc/kibana':
        ensure  => directory,
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
    }

    file { '/etc/kibana/config.js':
        ensure  => present,
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///files/kibana/config.js',
        require => File['/etc/kibana'],
    }

}
# vim:sw=4 ts=4 sts=4 et:
