# == Class profile::analytics::cluster::repositories::statistics
#
# Specific repositories that should be deployed on analytics statistics
# nodes and the hadoop coordinator.
#
class profile::analytics::cluster::repositories::statistics {

    # Repository needed to help various scripts to get the
    # mapping between wiki name and section (example: enwiki => s1).
    # The information is in turn used to get the mapping between
    # wiki name and dbstore host on which the correspondent database
    # is deployed.
    git::clone { 'operations/mediawiki-config':
        ensure             => 'latest',
        directory          => '/srv/mediawiki-config',
        recurse_submodules => true,
    }
}