# Class: tilerator::regen
class tilerator::regen (
    $osmosis_dir    = '/srv/osmosis',
    $generator_id   = 'gen',
    $storage_id     = 'v3',
    $delete_empty   = true,
    $expire_dir     = '/srv/osm_expire/',
    $statefile_dir  = '/var/run/tileratorui',
) {

    $tilerator_log_dir = '/var/log/tilerator/'
    $statefile = "${statefile_dir}/expire.state"

    file { '/usr/local/bin/notify-tilerator-regen':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/tilerator/notify-tilerator-regen.sh',
    }

    file { $tilerator_log_dir:
        ensure => directory,
        owner  => 'tileratorui',
        group  => 'tileratorui',
        mode   => '0755',
    }

    logrotate::rule { 'regen-zoom-level':
        ensure       => present,
        file_glob    => "${tilerator_log_dir}/regen-zoom-level.log",
        frequency    => 'monthly',
        not_if_empty => true,
        max_age      => 30,
        rotate       => 30,
        date_ext     => true,
        compress     => true,
        missing_ok   => true,
        no_create    => true,
    }

    # Notify tilerator to regenerate zoom levels 0-9 monthly
    $regen_options = "${osmosis_dir} 0 9 ${generator_id} ${storage_id} ${delete_empty} ${expire_dir} ${statefile}"
    cron { "regen-zoom-level-${title}":
        ensure   => present,
        command  => "/usr/local/bin/notify-tilerator-regen ${regen_options} >> ${tilerator_log_dir}/regen-zoom-level.log 2>&1",
        user     => 'tileratorui',
        hour     => '12',
        minute   => '0',
        monthday => '15',
    }

}
