class snapshot::dumps::monitor( $ensure = present ) {
  base::service_unit { 'dumps-monitor':
    ensure    => $ensure,
    systemd   => true,
    upstart   => true,
    subscribe => File["${snapshot::dumps::dirs::dumpsdir}/confs/wikidump.conf.monitor"],
  }
}
