# == Class profile::analytics::cluster::repositories::statistics
#
# Specific repositories that should be deployed on analytics statistics
# nodes.
#
class profile::analytics::cluster::repositories::statistics {

    # Repository needed to help various scripts to get the
    # mapping between wiki name and section (example: enwiki => s1).
    # The information is in turn used to get the mapping between
    # wiki name and dbstore host on which the correspondent database
    # is deployed.
    if !defined(File['/srv/mediawiki']) {
        file { '/srv/mediawiki':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }
    }

    git::clone { 'operations/mediawiki-config':
        ensure             => 'latest',
        directory          => '/srv/mediawiki/mediawiki-config',
        recurse_submodules => true,
        require            => File['/srv/mediawiki']
    }
}