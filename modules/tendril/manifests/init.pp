# tendril: MariaDB Analytics

# NOTE: this does not install tendril.. it could be git deployed,
# but it hasn't been moved to a wmf repo.

class tendril (
    $site_name,
    $docroot,
    $ldap_binddn,
    $ldap_authurl,
    $ldap_groups,
    $auth_name,
) {

    include passwords::ldap::wmf_cluster
    $proxypass = $passwords::ldap::wmf_cluster::proxypass

    file { "/etc/apache2/sites-enabled/${site_name}":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => template("tendril/apache/${site_name}.erb");
    }


}
