class snapshot::dumps::monitor {
  $repodir = $snapshot::dumps::dirs::repodir
  $confsdir = $snapshot::dumps::dirs::confsdir

  base::service_unit { 'dumps-monitor':
    ensure    => 'present',
    systemd   => systemd_template('dumps-monitor'),
    upstart   => upstart_template('dumps-monitor'),
    subscribe => File["${confsdir}/wikidump.conf.dumps"],
  }
}
