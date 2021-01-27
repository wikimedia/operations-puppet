class snapshot::dumps::packages {
    $mysql_client_pkg = case $::lsbdistcodename {
        'buster': { 'default-mysql-client' }
        'stretch': { 'mysql-client' }
        default: { fail("Unsupported distro ${::lsbdistcodename}") }
    }
    ensure_packages(['mwbzutils',
                    'p7zip-full',
                    $mysql_client_pkg,
                    'lbzip2',
                    'python3-yaml'])
}
