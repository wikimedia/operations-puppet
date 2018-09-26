# Class: tilerator::regen
#
# Provides for periodically regenerating low-zoom map tiles
#
# [*osmosis_dir*]
#   directory in which osmosis keeps its state
#
# [*generator_id*]
#   source to copy tiles from ("gen" will only produce non-empty tiles)
#
# [*storage_id*]
#   source to copy tiles to
#
# [*delete_empty*]
#   if tile is empty, make sure we don't store it, if it was there before
#
# [*expire_dir*]
#   expire directory location
#
# [*statefile_dir*]
#   directory containing the state file from OSM
#
# [*from_zoom*]
#   new jobs will be created from this zoom
#
# [*before_zoom*]
#   and until (but not including) this zoom
#
class tilerator::regen (
    Stdlib::Absolutepath $osmosis_dir   = '/srv/osmosis',
    String $generator_id                = 'gen',
    String $storage_id                  = 'v3',
    Boolean $delete_empty               = true,
    Stdlib::Absolutepath $expire_dir    = '/srv/osm_expire/',
    Stdlib::Absolutepath $statefile_dir = '/var/run/tileratorui',
    Integer[0, 19] $from_zoom           = 0,
    Integer[0, 19] $before_zoom         = 10,
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
    $regen_options = "${osmosis_dir} ${from_zoom} ${before_zoom} ${generator_id} ${storage_id} ${delete_empty} ${expire_dir} ${statefile}"
    cron { "regen-zoom-level-${title}":
        ensure   => present,
        command  => "/usr/local/bin/notify-tilerator-regen ${regen_options} >> ${tilerator_log_dir}/regen-zoom-level.log 2>&1",
        user     => 'tileratorui',
        hour     => '12',
        minute   => '0',
        monthday => '15',
    }

}
