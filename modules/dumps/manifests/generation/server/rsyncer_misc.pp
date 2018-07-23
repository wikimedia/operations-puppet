class dumps::generation::server::rsyncer_misc(
    $miscdumpsdir = undef,
    $miscremotedirs = undef,
    $miscsubdirs = undef,
    $miscremotesubs = undef,
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
        restart   => true,
        content   => systemd_template('dumps-rsync-peers-misc'),
        subscribe => File['/usr/local/bin/rsync-to-peers.sh'],
    }
}
