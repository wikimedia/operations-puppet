class dumps::generation::server::rsyncer(
    $xmldumpsdir = undef,
    $xmlremotedirs = undef,
    $miscdumpsdir = undef,
    $miscremotedirs = undef,
)  {
    file { '/usr/local/bin/rsync-to-peers.sh':
        ensure => 'present',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/generation/rsync-to-peers.sh',
    }

    systemd::service { 'dumps-rsyncer':
        ensure    => 'present',
        content   => systemd_template('dumps-rsync-peers'),
        subscribe => File['/usr/local/bin/rsync-to-peers.sh'],
    }
}
