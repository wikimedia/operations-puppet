class snapshot::dumps::packages {
    ensure_packages(['mwbzutils',
                    'p7zip-full',
                    'default-mysql-client',
                    'lbzip2',
                    'python3-yaml'])
}
