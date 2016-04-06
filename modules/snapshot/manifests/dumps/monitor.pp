class snapshot::dumps::monitor( $ensure = present ) {
  include snapshot::dumps::dirs

  $repodir = $snapshot::dumps::dirs::repodir
  $confsdir = $snapshot::dumps::dirs::confsdir

  base::service_unit { 'dumps-monitor':
    ensure    => $ensure,
    systemd   => true,
    upstart   => true,
    subscribe => File["${confsdir}/wikidump.conf.monitor"],
  }
}
