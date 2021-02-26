# === Class deployment::rsync
#
# Simple class to allow syncing of the deployment directory.
#
class deployment::rsync(
    Stdlib::Host $deployment_server,
    Wmflib::Ensure $job_ensure = 'absent',
    Array[Stdlib::Host] $deployment_hosts = [],
    Stdlib::Unixpath $deployment_path = '/srv/deployment',
    Stdlib::Unixpath $patches_path = '/srv/patches',
){

    include ::rsync::server

    rsync::server::module { 'deployment_home':
        path        => '/home',
        read_only   => 'yes',
        hosts_allow => $deployment_hosts,
    }

    rsync::server::module { 'deployment_module':
        path        => $deployment_path,
        read_only   => 'yes',
        hosts_allow => $deployment_hosts,
    }

    $sync_command = "/usr/bin/rsync -avz --delete ${deployment_server}::deployment_module ${deployment_path}"

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

    rsync::server::module { 'patches_module':
        path        => $patches_path,
        read_only   => 'yes',
        hosts_allow => $deployment_hosts,
    }

    $sync_patches_command = "/usr/bin/rsync -avz --delete ${deployment_server}::patches_module ${patches_path}"

    systemd::timer::job { 'sync_patches_dir':
        ensure      => $job_ensure,
        user        => 'root',
        description => "rsync the deployment server patches directory ${patches_path}",
        command     => $sync_patches_command,
        interval    => [
            {
            'start'    => 'OnBootSec', # initially start the unit
            'interval' => '15sec',
            },{
            'start'    => 'OnCalendar',
            'interval' => '*-*-* *:30:00', # then hourly on the half hour
            },
        ],
    }
}
