# == Class role::ci:slave::labs::docker
#
# Experimental Jenkins slave instance for providing Docker based CI builds.
#
class role::ci::slave::labs::docker {
    requires_realm('labs')

    system::role { 'role::ci::slave::labs::docker':
        description => 'CI Jenkins slave using Docker on labs' }

    include role::ci::slave::labs::common
    include profile::ci::docker
    include profile::ci::gitcache
    include profile::ci::worker_localhost
    include profile::phabricator::arcanist
    include profile::zuul::cloner
}
