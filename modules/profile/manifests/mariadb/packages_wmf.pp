class profile::mariadb::packages_wmf (
    Optional[String[1]] $package = lookup('mariadb::package', { 'default_value' => undef }),
) {
    if $package != undef {
        $mariadb_package = $package
    } elsif debian::codename::eq('bookworm') {
        $mariadb_package = 'wmf-mariadb106'
    } elsif debian::codename::eq('bullseye') {
        $mariadb_package = 'wmf-mariadb104'
    } else {
        fail("Debian release ${facts['os']['distro']['codename']} is not supported")
    }
    class { 'mariadb::packages_wmf': package => $mariadb_package }

    $basedir = "/opt/${mariadb_package}"
}
