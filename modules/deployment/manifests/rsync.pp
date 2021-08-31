# === Class deployment::rsync
#
# Simple class to allow syncing of the deployment directory.
#
class deployment::rsync(
    Stdlib::Host $deployment_server,
    Array[Stdlib::Host] $deployment_hosts = [],
    Stdlib::Unixpath $deployment_path = '/srv/deployment',
    Stdlib::Unixpath $patches_path = '/srv/patches',
){
    rsync::quickdatacopy { 'deployment_home':
        source_host         => $deployment_server,
        dest_host           => $deployment_hosts,
        module_path         => '/home',
        auto_sync           => false,
        server_uses_stunnel => true,
    }

    rsync::quickdatacopy { 'deployment_module':
        source_host         => $deployment_server,
        dest_host           => $deployment_hosts,
        module_path         => $deployment_path,
        auto_sync           => true,
        delete              => true,
        auto_interval       => [
            {
            'start'    => 'OnBootSec', # initially start the unit
            'interval' => '10sec',
            },{
            'start'    => 'OnCalendar',
            'interval' => '*-*-* *:00:00', # then hourly on the hour
            },
        ],
        server_uses_stunnel => true,
    }

    rsync::quickdatacopy { 'patches_module':
        source_host         => $deployment_server,
        dest_host           => $deployment_hosts,
        module_path         => $patches_path,
        auto_sync           => true,
        delete              => true,
        auto_interval       => [
            {
            'start'    => 'OnBootSec', # initially start the unit
            'interval' => '15sec',
            },{
            'start'    => 'OnCalendar',
            'interval' => '*-*-* *:30:00', # then hourly on the half hour
            },
        ],
        server_uses_stunnel => true,
    }

    # TODO: remove everything below after running puppet
    $sync_command = "/usr/bin/rsync -avz --delete ${deployment_server}::deployment_module ${deployment_path}"

    systemd::timer::job { 'sync_deployment_dir':
        ensure      => absent,
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

    $sync_patches_command = "/usr/bin/rsync -avz --delete ${deployment_server}::patches_module ${patches_path}"

    systemd::timer::job { 'sync_patches_dir':
        ensure      => absent,
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
