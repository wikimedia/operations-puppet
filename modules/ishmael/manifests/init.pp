# ishmael: A UI for mk-query-digest
# http://mihasya.com/blog/a-ui-for-mk-query-digest/
# https://github.com/mihasya/ishmael

# NOTE: this does not install ishmael.. it could be git deployed,
# but it hasn't been moved to a wmf repo. for now:
# cd /srv ; git clone https://github.com/asher/ishmael.git ;
# cd ishmael ; git clone https://github.com/asher/ishmael.git sample
#
class ishmael (
    $site_name     = 'ishmael.wikimedia.org',
    $config_main   = '/srv/ishmael/conf.php',
    $config_sample = '/srv/ishmael/sample/conf.php',
    $docroot       = '/srv/ishmael',
    $ssl_cert      = 'star.wikimedia.org',
    $ssl_ca        = 'RapidSSL_CA',
    $ldap_binddn   = 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org',
    $ldap_authurl  = 'ldaps://virt0.wikimedia.org virt1000.wikimedia.org/ou=people,dc=wikimedia,dc=org?cn',
    $ldap_group    = 'cn=wmf,ou=groups,dc=wikimedia,dc=org',
    $auth_name     = 'WMF Labs (use wiki login name not shell)',
) {

    include passwords::ldap::wmf_cluster
    $proxypass = $passwords::ldap::wmf_cluster::proxypass

    file { "/etc/apache2/sites-available/${site_name}":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => template("ishamel/apache/${site_name}.erb");
    }

    install_certificate{ $sslcert: }

    apache_site { 'ishmael': name => $site_name }

    ishmael::config { $config_main: }

    ishmael::config { $config_sample:
        review_table  => '%tcpquery_review',
        history_table => '%tcpquery_review_history',
    }
}
