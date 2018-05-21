class snapshot::dumps::monitor(
    $xmldumpsuser = undef,
    $xmldumpsgroup = undef,
) {
  $repodir = $snapshot::dumps::dirs::repodir
  $confsdir = $snapshot::dumps::dirs::confsdir

  systemd::service { 'dumps-monitor':
    ensure    => 'present',
    content   => systemd_template('dumps-monitor'),
    subscribe => File["${confsdir}/wikidump.conf.dumps"],
  }
}
