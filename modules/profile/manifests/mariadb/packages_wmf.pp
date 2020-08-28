class profile::mariadb::packages_wmf (
    Optional[String[1]] $package = lookup('mariadb::package', { 'default_value' => undef }),
) {
    if $package != undef {
        $mariadb_package = $package
    } elsif os_version('debian == buster') {
        $mariadb_package = 'wmf-mariadb104'
    } elsif os_version('debian == stretch') {
        $mariadb_package = 'wmf-mariadb101'
    } else {
        fail("Debian release ${facts['os']['distro']['codename']} is not supported")
    }
    class { 'mariadb::packages_wmf': package => $mariadb_package }

    $basedir = "/opt/${mariadb_package}"
}
