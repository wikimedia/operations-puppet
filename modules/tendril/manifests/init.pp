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

    apache::site { $site_name:
        content => template("tendril/apache/${site_name}.erb");
    }


}
