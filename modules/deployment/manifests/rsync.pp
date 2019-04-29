# === Class deployment::rsync
#
# Simple class to allow syncing of the deployment directory.
#

class deployment::rsync(
    $deployment_server,
    $cron_ensure = 'absent',
    Array[String] $deployment_hosts = [],
) {
    include ::rsync::server

    rsync::server::module { 'trebuchet_server':
        path        => '/srv/deployment',
        read_only   => 'yes',
        hosts_allow => $deployment_hosts,
    }

    cron { 'sync_deployment_dir':
        ensure  => $cron_ensure,
        command => "/usr/bin/rsync -avz --delete ${deployment_server}::trebuchet_server /srv/deployment > /dev/null 2>&1",
        minute  => 0,
    }


}
