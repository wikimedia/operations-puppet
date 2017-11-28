# class of common setups needed by several roles on labsdb
class role::labs::db::common {
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
