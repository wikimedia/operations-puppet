class profile::wmcs::db::scriptconfig {
    # The wikireplicas and sanitarium need some config for check_private_data
    # and the view management scripts
    require ::profile::mariadb::wmfmariadbpy
    require_package (
        'python3-yaml',
        'python3-pymysql',
    )
    git::clone { 'operations/mediawiki-config':
        ensure             => 'latest',
        directory          => '/usr/local/lib/mediawiki-config',
        recurse_submodules => true,
    }
}
