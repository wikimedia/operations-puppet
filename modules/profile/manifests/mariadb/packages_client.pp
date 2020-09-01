class profile::mariadb::packages_client (
    Optional[String[1]] $package = lookup('mariadb::package_client', { 'default_value' => undef }),
) {
    if $package != undef {
        $mariadb_client_package = $package
    } elsif os_version('debian == buster') {
        $mariadb_client_package = 'wmf-mariadb104-client'
    } elsif os_version('debian == stretch') {
        $mariadb_client_package = 'wmf-mariadb101-client'
    } else {
        fail("Debian release ${facts['os']['distro']['codename']} is not supported")
    }
    class { 'mariadb::packages_client': package => $mariadb_client_package }

    $basedir = "/opt/${mariadb_client_package}"
}
