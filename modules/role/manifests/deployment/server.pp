# filtertags: labs-project-deployment-prep labs-project-phabricator labs-project-striker
class role::deployment::server(
    $apache_fqdn = $::fqdn,
    $deployment_group = 'wikidev',
) {

    include ::standard
    include profile::scap::master

    # TODO: move below to profiles
    #
    # Much of this is shared config of trebuchet and scap3. Fully removing
    # trebuchet will make this much easier to sort in separate profiles.
    include ::deployment::umask_wikidev

    class { 'deployment::deployment_server':
        deployment_group => $deployment_group,
    }

    include ::apache
    # Install apache-fast-test
    include ::apache::helper_scripts
    include mysql

    include network::constants
    $deployable_networks = $::network::constants::deployable_networks

    $deployable_networks_ferm = join($deployable_networks, ' ')

    # Firewall rules
    # T113351
    ferm::service { 'http_deployment_server':
        desc   => 'http on trebuchet deployment servers, for serving actual files to deploy',
        proto  => 'tcp',
        port   => '80',
        srange => "(${deployable_networks_ferm})",
    }

    ### End firewall rules

    ### Trebuchet
    file { '/srv/deployment':
        ensure => directory,
        owner  => 'trebuchet',
        group  => $deployment_group,
    }

    apache::site { 'deployment':
        content => template('role/deployment/apache-vhost.erb'),
        require => File['/srv/deployment'],
    }

    $deployment_server = hiera('deployment_server', 'tin.eqiad.wmnet')
    class { '::deployment::redis':
        deployment_server => $deployment_server
    }

    # Bacula backups (T125527)
    backup::set { 'srv-deployment': }

    # Used by the trebuchet salt returner
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
    ### End Trebuchet


    # tig is a ncurses-based git utility which is useful for
    # determining the state of git repos during deployments.

    require_package('percona-toolkit', 'tig')

    # Bug T126262
    require_package('php5-readline')
}
