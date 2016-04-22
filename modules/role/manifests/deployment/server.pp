class role::deployment::server(
    $apache_fqdn = $::fqdn,
    $deployment_group = 'wikidev',
) {
    include standard

    # Can't include this while scap is present on the deployment server:
    # include misc::deployment::scripts
    include role::deployment::mediawiki

    # scap::server will ensure that all keyholder::agents and scap::sources
    # declared in hiera will exist.  scap::server is
    # for generic repository deployment and does not have
    # anything to do with Mediawiki.
    include scap::server

    # set umask for wikidev users so that newly-created files are g+w
    file { '/etc/profile.d/umask-wikidev.sh':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        # NOTE: This file is also used in role::statistics
        source => 'puppet:///modules/role/deployment/umask-wikidev-profile-d.sh',
    }

    include ::apache
    # Install apache-fast-test
    include ::apache::helper_scripts
    include mysql

    include network::constants
    $deployable_networks = $::network::constants::deployable_networks

    if $::realm != 'labs' {
        include role::microsites::releases::upload
        # backup /home dirs on deployment servers
        include role::backup::host
        backup::set {'home': }
    }

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
        remote_branch => 'readonly/master'
    }

    class { 'role::deployment::apache':
        apache_fqdn => $apache_fqdn,
    }

    $deployment_server = hiera('deployment_server', 'tin.eqiad.wmnet')
    $deploy_ensure = $deployment_server ? {
        $::fqdn => 'absent',
        default => 'present'
    }
    motd::script { 'inactive_warning':
        ensure   => $deploy_ensure,
        priority => 01,
        source   => 'puppet:///modules/role/deployment/inactive.motd',
    }

    class { '::role::deployment::trebuchet_server':
        apache_fqdn      => $apache_fqdn,
        deployment_group => $deployment_group,
    }

    # tig is a ncurses-based git utility which is useful for
    # determining the state of git repos during deployments.

    require_package 'percona-toolkit', 'tig'

    # Bug T126262
    require_package 'php5-readline'
}
