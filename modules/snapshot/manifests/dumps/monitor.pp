class snapshot::dumps::monitor( $ensure = present ) {
  include snapshot::dumps::dirs

  $repodir = $snapshot::dumps::dirs::repodir

  base::service_unit { 'dumps-monitor':
    ensure    => $ensure,
    systemd   => true,
    upstart   => true,
    subscribe => File["${snapshot::dumps::dirs::dumpsdir}/confs/wikidump.conf.monitor"],
  }
}
