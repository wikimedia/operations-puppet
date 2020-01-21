# Contact in the remote end: "zigo" Thomas Goirand <zigo@debian.org>
class mirrors::openstack {
    require mirrors

    $local_dir = '/srv/mirrors/osbpo'
    $remote_path = 'osbpo.debian.net::osbpo/'

    file { $local_dir:
        ensure => directory,
        owner  => 'mirror',
        group  => 'mirror',
        mode   => '0755',
    }

    $rsync_cmd = "/usr/bin/rsync -rt --delete ${remote_path} ${local_dir}"
    systemd::timer::job { 'update-openstack-mirror':
        ensure              => present,
        description         => 'Update mirror for openstack repository',
        command             => "${rsync_cmd} 1>/dev/null 2>/dev/null",
        interval            => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* 08:00:00', # daily at 08:00 UTC as requested
        },
        max_runtime_seconds => 72000, # kill if running after 20h
        monitoring_enabled  => false,
        user                => 'mirror',
    }
}
