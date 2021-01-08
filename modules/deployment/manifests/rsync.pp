# === Class deployment::rsync
#
# Simple class to allow syncing of the deployment directory.
#
class deployment::rsync(
    Stdlib::Host $deployment_server,
    Wmflib::Ensure $job_ensure = 'absent',
    Array[Stdlib::Host] $deployment_hosts = [],
    Stdlib::Unixpath $deployment_path = '/srv/deployment',
){

    include ::rsync::server

    rsync::server::module { 'trebuchet_server':
        path        => $deployment_path,
        read_only   => 'yes',
        hosts_allow => $deployment_hosts,
    }

    cron { 'sync_deployment_dir':
        ensure  => 'absent',
        command => "/usr/bin/rsync -avz --delete ${deployment_server}::trebuchet_server /srv/deployment > /dev/null 2>&1",
        minute  => 0,
    }

    $sync_command = "/usr/bin/rsync -avz --delete ${deployment_server}::trebuchet_server ${deployment_path}"

    systemd::timer::job { 'sync_deployment_dir':
        ensure      => $job_ensure,
        user        => 'root',
        description => "rsync the deployment server data directory ${deployment_path}",
        command     => $sync_command,
        interval    => [
            {
            'start'    => 'OnBootSec', # initially start the unit
            'interval' => '10sec',
            },{
            'start'    => 'OnCalendar',
            'interval' => '*-*-* *:00:00', # then hourly on the hour
            },
        ],
    }
}
