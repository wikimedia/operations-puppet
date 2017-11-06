class dumps::generation::server::rsyncer(
    $dumpsdir = undef,
    $remotedirs = undef,
)  {
    file { '/usr/local/bin/rsync-to-peers.sh':
        ensure => 'present',
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/generation/rsync-to-peers.sh'),
    }

    base::service_unit { 'dumps-rsyncer':
        ensure    => 'present',
        systemd   => systemd_template('dumps-rsync-peers'),
        upstart   => upstart_template('dumps-rsync-peers'),
        subscribe => File['/usr/local/bin/rsync-to-peers.sh'],
    }
}
