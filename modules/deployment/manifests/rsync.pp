# === Class deployment::rsync
#
# Simple class to allow syncing of the deployment directory.
#
class deployment::rsync(
    Stdlib::Fqdn $deployment_server,
    Array[Stdlib::Fqdn] $deployment_hosts = [],
    Stdlib::Unixpath $deployment_path     = '/srv/deployment',
    Stdlib::Unixpath $patches_path        = '/srv/patches',
){
    if $deployment_hosts.length > 0
    {
        rsync::quickdatacopy { 'deployment_home':
            source_host         => $deployment_server,
            dest_host           => $deployment_hosts,
            module_path         => '/home',
            auto_sync           => false,
            server_uses_stunnel => false,
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
            server_uses_stunnel => false,
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
            server_uses_stunnel => false,
        }
    }
}
