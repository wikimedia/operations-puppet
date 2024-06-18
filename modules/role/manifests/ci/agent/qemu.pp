class role::ci::agent::qemu {
    requires_realm('labs')

    include profile::ci::slave::labs::common
    include profile::ci::docker

    # Extended volume for /var/lib/docker
    include profile::ci::dockervolume

    include profile::ci::qemu
}
