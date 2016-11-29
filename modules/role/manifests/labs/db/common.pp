# class of common setups needed by several roles on labsdb
class role::labs::db::common {
    package {
        ['python3-yaml', 'python3-pymysql']:
            ensure => present,
    }

    git::clone { 'operations/mediawiki-config':
        ensure             => 'latest',
        directory          => '/usr/local/lib/mediawiki-config',
        recurse_submodules => true,
    }
}
