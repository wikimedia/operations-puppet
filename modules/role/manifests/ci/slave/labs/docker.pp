# == Class role::ci:slave::labs::docker
#
# Experimental Jenkins slave instance for providing Docker based CI builds.
#
class role::ci::slave::labs::docker {
    requires_realm('labs')

    include profile::ci::slave::labs::common
    include profile::ci::docker
    # Extended volume for /var/lib/docker
    include profile::ci::dockervolume
    include profile::ci::gitcache
}
