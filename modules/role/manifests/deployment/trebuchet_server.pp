class role::deployment::trebuchet_server(
    $apache_fqdn = $::fqdn,
    $deployment_group = 'wikidev',
) {
    class { 'role::deployment::apache':
        apache_fqdn => $apache_fqdn,
    }

    class { 'deployment::deployment_server':
        deployment_group => $deployment_group,
    }

    $deployment_server = hiera('deployment_server', 'tin.eqiad.wmnet')
    class { '::deployment::redis':
        deployment_server => $deployment_server
    }

    $deploy_ensure = $deployment_server ? {
        $::fqdn => 'absent',
        default => 'present'
    }

    class { '::deployment::rsync':
        deployment_server => $deployment_server,
        cron_ensure       => $deploy_ensure,
    }

    # Bacula backups (T125527)
    backup::set { 'srv-deployment': }

    # Used by the trebuchet salt returner
    include network::constants
    $deployable_networks = $::network::constants::deployable_networks
    $deployable_networks_ferm = join($deployable_networks, ' ')
    ferm::service { 'deployment-redis':
        proto  => 'tcp',
        port   => '6379',
        srange => "(${deployable_networks_ferm})",
    }

    sudo::group { "${deployment_group}_deployment_server":
        group      => $deployment_group,
        privileges => [
            'ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet --out=json pillar.data',
            'ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet publish.runner deploy.fetch *',
            'ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet publish.runner deploy.checkout *',
            'ALL = (root) NOPASSWD: /usr/bin/salt-call -l quiet --out=json publish.runner deploy.restart *',
        ],
    }
}
