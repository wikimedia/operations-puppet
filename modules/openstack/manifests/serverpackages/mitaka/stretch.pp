class openstack::serverpackages::mitaka::stretch(
) {

    # hack, use the jessie-backports repository in stretch. This should work,
    # since jessie-backports packages are rebuilt from stretch anyway
    require openstack::commonpackages::mitaka

    # in stretch, these packages are included in both our custom repo component
    # and in the stretch stable repo. Avoid conflicts with apt by avoiding
    # installing the version from our custom repo.
    $avoid_packages = [
        'python-cryptography',
        'libpq5',
        'libisns0',
        'libjs-sphinxdoc',
        'python-sphinx',
        'sphinx-common',
        'sqlite3',
        'pdns-recursor',
        'python-openssl',
        'openssl',
        'libjs-jquery',
    ]

    $avoid_packages_list = join($avoid_packages, ' ')
    apt::pin { 'mitaka_stretch_nojessiebpo':
        package  => $avoid_packages_list,
        pin      => 'release c=openstack-mitaka-jessie',
        priority => '-1',
    }
}
