# === Class deployment::rsync
#
# Simple class to allow syncing of the deployment directory.
#

class deployment::rsync {
    $deployment_server = hiera('deployment_server', 'tin.eqiad.wmnet')

    include rsync::server

    rsync::server::module { 'trebuchet_server':
        path        => '/srv/deployment',
        read_only   => 'yes',
        hosts_allow => $::network::constants::special_hosts[$realm]['deployment_hosts'],
    }

    if ($deployment_server == $::fqdn) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    cron { 'sync_deployment_dir':
        ensure  => $ensure,
        command => "/usr/bin/rsync -avz --delete rsync://${deployment_server}/srv/deployment /srv/deployment > /dev/null 2>&1",
        minute  => 0,
    }


}
