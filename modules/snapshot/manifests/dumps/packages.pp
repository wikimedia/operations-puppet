class snapshot::dumps::packages {
    ensure_packages(['mwbzutils',
                    'mysql-client',
                    'p7zip-full',
                    'lbzip2',
                    'python3-yaml'])
}
