class authdns::rsync {
    require authdns::config
    include rsync::server
    include network::constants

    $staging_dir = "/srv/authdns/staging-rsync"

    file { $staging_dir:
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    rsync::server::module { 'authdns-rsync':
        path            => $staging_dir,
        read_only       => 'yes',
        uid             => 'nobody',
        gid             => 'nogroup',
        hosts_allow     => $::network::constants::production_networks,
        max_connections => 25,
        require         => File[$staging_dir],
    }

    ferm::service { 'authdns-rsync':
        proto  => 'tcp',
        port   => '873',
        srange => '$PRODUCTION_NETWORKS',
    }
}
