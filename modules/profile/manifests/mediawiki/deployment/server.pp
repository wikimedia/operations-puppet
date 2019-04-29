# filtertags: labs-project-deployment-prep labs-project-phabricator labs-project-striker
class profile::mediawiki::deployment::server(
    $apache_fqdn = hiera('apache_fqdn', $::fqdn),
    $deployment_group = hiera('deployment_group', 'wikidev'),
    $deployment_server = hiera('deployment_server'),
    $main_deployment_server = hiera('scap::deployment_server'),
    $base_path = hiera('base_path', '/srv/deployment'),
    Array[String] $deployment_hosts = hiera('deployment_hosts', []),
) {

    ## Scap Config ##
    require ::scap

    # Create an instance of $keyholder_agents for each of the key specs.
    create_resources('keyholder::agent', hiera('scap::keyholder_agents', {}))

    # Create an instance of scap_source for each of the key specs in hiera.
    Scap::Source {
        base_path => $base_path,
    }

    create_resources('scap::source', hiera('scap::sources', {}))
    ## End scap config ###

    class {'::deployment::umask_wikidev': }

    class { '::deployment::deployment_server':
        deployment_group => $deployment_group,
    }

    class {'::apache': }

    require_package('mysql-client')

    include network::constants
    $deployable_networks = $::network::constants::deployable_networks
    $deployable_networks_ferm = join($deployable_networks, ' ')

    ferm::service { 'rsyncd_scap_master':
        proto  => 'tcp',
        port   => '873',
        srange => '$MW_APPSERVER_NETWORKS',
    }


    # T113351
    ferm::service { 'http_deployment_server':
        desc   => 'HTTP on deployment servers, for serving actual files to deploy',
        proto  => 'tcp',
        port   => '80',
        srange => "(${deployable_networks_ferm})",
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

    file { '/srv/deployment':
        ensure => directory,
        owner  => 'trebuchet',
        group  => $deployment_group,
    }

    apache::site { 'deployment':
        content => template('role/deployment/apache-vhost.erb'),
        require => File['/srv/deployment'],
    }

    $deploy_ensure = $deployment_server ? {
        $::fqdn => 'absent',
        default => 'present'
    }

    class { '::deployment::rsync':
        deployment_server => $deployment_server,
        cron_ensure       => $deploy_ensure,
        deployment_hosts  => $deployment_hosts,
    }

    motd::script { 'inactive_warning':
        ensure   => $deploy_ensure,
        priority => 1,
        content  => template('role/deployment/inactive.motd.erb'),
    }

    if $deploy_ensure == 'present' {
        # Lock the passive servers, leave untouched the active one.
        file { '/var/lock/scap-global-lock':
            ensure  => 'present',
            owner   => 'root',
            group   => 'root',
            content => "Not the active deployment server, use ${main_deployment_server}",
        }
    }

    # Bacula backups (T125527)
    backup::set { 'srv-deployment': }

    # tig is a ncurses-based git utility which is useful for
    # determining the state of git repos during deployments.
    require_package('percona-toolkit', 'tig')
    if os_version('debian >= stretch') {
        require_package('php7.0-readline') # bug T126262
    } else {
        require_package('php5-readline') # bug T126262
    }


}
