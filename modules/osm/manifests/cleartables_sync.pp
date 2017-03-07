class osm::cleartables_sync (
    $pg_password,
    $ensure = 'present',
    $hour   = '*',
    $minute = '*/30',
) {

    $log_dir = '/var/log/osm_replication/'

    file { '/usr/local/bin/process-osm-data':
      ensure => present,
      owner  => 'root',
      group  => 'root',
      mode   => '0555',
      source => "puppet:///modules/osm/process-osm-data.sh",
    }

    cron { "planet_sync-${name}":
      ensure      => $ensure,
      command     => "/usr/local/bin/process-osm-data planet-update >> ${log_dir}/planet-update.log 2>&1",
      user        => 'osmupdater',
      hour        => $hour,
      minute      => $minute,
      environment => [ "PGPASSWORD=${pg_password}" ],
    }

}