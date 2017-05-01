# == Class profile::scap::master
#
# Setup scap server
class profile::scap::master(
    $keyholder_user           = hiera('scap::master::keyholder_user'),
    $keyholder_group          = hiera('scap::master::keyholder_group', []),
    $keyholder_agents         = hiera('scap::master::keyholder_agents', {}),
    $keyholder_sources        = hiera('scap::master::keyholder_sources', {}),
    $deployment_group         = hiera('scap::master::deployment_group'),
    $active_deployment_server = hiera('scap::master::deployment_server'),
) {
    include ::profile::mediawiki::nutcracker
    include ::profile::scap::dsh

    if $::realm != 'labs' {
        include role::microsites::releases::upload
        # backup /home dirs on deployment servers
        include ::profile::backup::host
        backup::set {'home': }
    }

    # Base scap setup
    class { '::scap':
        active_deployment_server => $active_deployment_server,
    }
    class { '::scap::ferm': }
    class { '::scap::master':
        active_deployment_server => $active_deployment_server,
        deployment_group         => $deployment_group,
    }

    # All needed classes for deploying mediawiki
    class { '::mediawiki': }
    class { '::mediawiki::packages::php5': }

    # Keyholder
    class { '::keyholder': }
    class { '::keyholder::monitoring': }

    # Resources
    keyholder::agent { $keyholder_user:
        trusted_groups  => $keyholder_group,
    }

    ## Scap Config ##
    # Create an instance of $keyholder_agents for each of the key specs.
    create_resources('keyholder::agent', $keyholder_agents)

    $base_path = '/srv/deployment'

    # Create an instance of scap_source for each of the key specs in hiera.
    Scap::Source {
        base_path => $base_path,
    }

    create_resources('scap::source', $keyholder_sources)
    ## End scap config ###

    # Firewall rules
    ferm::service { 'rsyncd_scap_master':
        proto  => 'tcp',
        port   => '873',
        srange => '$MW_APPSERVER_NETWORKS',
    }
    ### End firewall rules

    #T83854
    ::monitoring::icinga::git_merge { 'mediawiki_config':
        dir           => '/srv/mediawiki-staging/',
        user          => 'root',
        remote        => 'readonly',
        remote_branch => 'master',
    }

    # Also make sure that no files have been stolen by root ;-)
    ::monitoring::icinga::bad_directory_owner { '/srv/mediawiki-staging': }

    $deploy_ensure = $active_deployment_server ? {
        $::fqdn => 'absent',
        default => 'present'
    }

    class { '::deployment::rsync':
        deployment_server => $active_deployment_server,
        cron_ensure       => $deploy_ensure,
    }

    motd::script { 'inactive_warning':
        ensure   => $deploy_ensure,
        priority => 01,
        content  => template('role/deployment/inactive.motd.erb'),
    }

    file { '/var/lock/scap-global-lock':
        ensure  => $deploy_ensure,
        owner   => 'root',
        group   => 'root',
        content => "Not the active deployment server, use ${active_deployment_server}",
    }
}
