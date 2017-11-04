class dumps::generation::server::rsyncer(
    $dumpsdir = undef,
    $remotedirs = undef,
)  {
  base::service_unit { 'dumps-rsyncer':
    ensure    => 'present',
    systemd   => systemd_template('dumps-rsync-peers'),
    upstart   => upstart_template('dumps-rsync-peers'),
    subscribe => File['/usr/local/bin/rsync-to-peers.sh'],
  }
}
