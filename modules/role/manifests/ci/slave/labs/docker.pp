# == Class role::ci:slave::labs::docker
#
# Experimental Jenkins slave instance for providing Docker based CI builds.
#
# === Parameters
#
# [*docker_lvm_volume*]
#
#   Give Docker its own volume mounted at /var/lib/docker. This uses 70% of
#   /dev/vda4 and leaves the rest for /srv. This should be used for instance
#   types with larger disks (xlarge, bigram, etc.).
#
# filtertags: labs-project-integration
class role::ci::slave::labs::docker(
    $docker_lvm_volume = false,
) {
    requires_realm('labs')

    system::role { 'role::ci::slave::labs::docker':
        description => 'CI Jenkins slave using Docker on labs' }

    include role::ci::slave::labs::common
    include profile::ci::docker
    include profile::ci::gitcache
    include profile::ci::worker_localhost
    include profile::phabricator::arcanist

    # If specified, give Docker its own volume mounted at /var/lib/docker
    if $docker_lvm_volume {
        include profile::ci::dockervolume
    }
}
