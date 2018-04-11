define osm::populate_admin (
    Wmflib::Ensure $ensure = present,
    Integer $hour          = 12,
    Integer $minute        = 5,
    String $weekday        = 'Tuesday',
    String $log_dir        = '/var/log/osm'
) {

    file { $log_dir:
        ensure => directory,
        owner  => 'postgres',
        group  => 'postgres',
        mode   => '0755',
    }
    cron { "populate_admin-${title}":
        ensure  => $ensure,
        command => "/usr/bin/psql -d ${title} -c 'SELECT populate_admin(); >> ${log_dir}/populate_admin.log 2>&1",
        user    => 'postgres',
        weekday => $weekday,
        hour    => $hour,
        minute  => $minute,
    }
    logrotate::rule { "populate_admin-${title}":
        ensure     => $ensure,
        file_glob  => "${log_dir}/populate_admin.log",
        frequency  => 'weekly',
        missing_ok => true,
        rotate     => 4,
        compress   => true,
    }

}
