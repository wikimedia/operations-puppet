# ishmael: A UI for mk-query-digest
# http://mihasya.com/blog/a-ui-for-mk-query-digest/
# https://github.com/mihasya/ishmael

# NOTE: this does not install ishmael.. it could be git deployed,
# but it hasn't been moved to a wmf repo. for now:
# cd /srv ; git clone https://github.com/asher/ishmael.git ;
# cd ishmael ; git clone https://github.com/asher/ishmael.git sample
#
class ishmael (
    $site_name,
    $ssl_cert,
    $ssl_ca,
    $config_main,
    $config_sample,
    $docroot,
    $ldap_binddn,
    $ldap_authurl,
    $ldap_group,
    $auth_name,
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

    install_certificate{ $ssl_cert: }

    apache_site { 'ishmael': name => $site_name }

    ishmael::config { $config_main: }

    ishmael::config { $config_sample:
        review_table  => '%tcpquery_review',
        history_table => '%tcpquery_review_history',
    }
}
