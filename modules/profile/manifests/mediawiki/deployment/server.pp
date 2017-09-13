# === Class profile::mediawiki::deployment::server
#
# Sets up scap and the corresponding apache site, and rsync daemon.
#
# filtertags: labs-project-deployment-prep labs-project-devtools labs-project-striker
class profile::mediawiki::deployment::server(
    Stdlib::Fqdn $apache_fqdn            = lookup('apache_fqdn', {default_value => $::fqdn}),
    String $deployment_group             = lookup('deployment_group', {default_value => 'wikidev'}),
    Stdlib::Fqdn $deployment_server      = lookup('deployment_server'),
    Stdlib::Fqdn $main_deployment_server = lookup('scap::deployment_server'),
    Stdlib::Unixpath $base_path          = lookup('base_path', {default_value => '/srv/deployment'}),
    Array[String] $deployment_hosts      = lookup('deployment_hosts', {default_value => []}),
    Stdlib::Host $rsync_host             = lookup('profile::mediawiki::deployment::server::rsync_host'),
    String $statsd                       = lookup('statsd'),
    Hash[String, Struct[{
                        'origin'          => Optional[String],
                        'repository'      => Optional[String],
                        'scap_repository' => Optional[String]
    }]] $sources  = lookup('scap::sources'),
) {
    # Class scap gets included via profile::mediawiki::common
    # Also a lot of needed things are called from there.
    require profile::mediawiki::common

    include network::constants
    $deployable_networks = $::network::constants::deployable_networks
    $deployable_networks_ferm = join($deployable_networks, ' ')
    # Install the scap master
    class { 'rsync::server': }

    class { '::scap::master':
        deployment_hosts => $deployment_hosts,
    }

    class { '::scap::scripts':
        rsync_host  => $rsync_host,
        sql_scripts => 'present',
        statsd      => $statsd,
    }

    # Create an instance of scap_source for each of the key specs in hiera.

    Scap::Source {
        base_path => $base_path,
    }

    $sources.each |$repo, $params| {
        scap::source { $repo:
            * => $params
        }
    }

    ## End scap config ###

    class {'::deployment::umask_wikidev': }

    class { '::deployment::deployment_server':
        deployment_group => $deployment_group,
    }

    class {'::httpd': }

    ensure_packages('default-mysql-client')

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

    # A command that group 'deployment' can execute to fix common file permission snafus
    # inside /srv/mediawiki-staging.
    file { '/usr/local/sbin/fix-staging-perms':
        mode   => '0555',
        source => 'puppet:///modules/profile/mediawiki/deployment/fix-staging-perms.sh',
        owner  => 'root',
        group  => 'root',
    }

    file { '/srv/deployment':
        ensure => directory,
        owner  => 'trebuchet',
        group  => $deployment_group,
    }

    httpd::site { 'deployment':
        content => template('role/deployment/apache-vhost.erb'),
        require => File['/srv/deployment'],
    }

    $deploy_ensure = $deployment_server ? {
        $::fqdn => 'absent',
        default => 'present'
    }

    class { '::deployment::rsync':
        deployment_server => $deployment_server,
        job_ensure        => $deploy_ensure,
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
    #   determining the state of git repos during deployments.
    # php-readline T126262
    ensure_packages(['percona-toolkit', 'tig'])

    # Make sure to install php-readline from the component/php72, otherwise this picks up
    # the 7.3 version from default buster
    apt::package_from_component { 'php-readline':
        component => 'component/php72',
        packages  => ['php-readline']
    }
    # benchmarking tools for sessionstorage testing (T230178)
    ensure_packages(['siege', 'wrk', 'lua-cjson'])
}
