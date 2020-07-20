class dumps::generation::server::rsyncer_common {
    file { '/usr/local/bin/rsync-via-primary.sh':
        ensure => 'present',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/generation/rsync-via-primary.sh',
    }

    file { '/usr/local/bin/rsyncer_lib.sh':
        ensure => 'present',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/generation/rsyncer_lib.sh',
    }
}
