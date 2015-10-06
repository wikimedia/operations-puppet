# = Define: labstore::fileserver::replicate
# Simple systemd based unit to replicate a given volume
# from current host to destination
#
# $calendar is the systemd OnCalendar value for when to
# schedule the backup.

define labstore::fileserver::replicate(
    $src_path,
    $dest_path,
    $dest_host,
    $calendar,
) {
    base::service_unit { "replicate-${title}":
        template_name   => 'replicate',
        ensure          => present,
        systemd         => true,
        declare_service => false,
    }

    # labstore::fileserver::replicate can only be applied to
    # Jessie hosts, so it is perfectly acceptable to presume
    # systemd.
    file { "/etc/systemd/system/replicate-${title}.timer":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('labstore/initscripts/replicate.timer.erb'),
    }

    nrpe::monitor_systemd_unit_state { "replicate-${title}":
        description    => "Last backup of the ${title} filesystem",
        expected_state => 'periodic 90000', # 25h (i.e. daily but with a bit of give)
    }
}
