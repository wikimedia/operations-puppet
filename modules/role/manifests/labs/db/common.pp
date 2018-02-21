# class of common setups needed by several roles on labsdb
class role::labs::db::common {
    require_package (
        'python3-yaml',
        'python3-pymysql',
    )

    $mwconfig = '/usr/local/lib/mediawiki-config'
    git::clone { 'operations/mediawiki-config':
        ensure             => 'latest',
        directory          => $mwconfig,
        recurse_submodules => true,
    }

    # T187850: clean up old submodule junk
    # TODO: remove this after it has run everywhere
    $firefoxos = 'docroot/wikimedia.org/WikipediaMobileFirefoxOS'
    file { [
        "${mwconfig}/${firefoxos}",
        "${mwconfig}/.git/modules/${firefoxos}",
    ]:
        ensure  => 'absent',
        recurse => true,
        purge   => true,
        force   => true,
        backup  => false,
        require => Git::Clone['operations/mediawiki-config'],
    }

}
