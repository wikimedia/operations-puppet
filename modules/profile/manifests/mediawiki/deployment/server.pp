# === Class profile::mediawiki::deployment::server
#
# Sets up scap and the corresponding apache site, and rsync daemon.
#
# The parameter "deployment_group" only refers to the group of people able to deploy mediawiki
# here, so to scap2 users. Scap3-related directories will be owned by wikidev unconditionally.
class profile::mediawiki::deployment::server(
    Stdlib::Fqdn $apache_fqdn            = lookup('apache_fqdn', {default_value => $::fqdn}),
    String $deployment_group             = lookup('deployment_group', {default_value => 'wikidev'}),
    Stdlib::Fqdn $deployment_server      = lookup('deployment_server'),
    Stdlib::Fqdn $main_deployment_server = lookup('scap::deployment_server'),
    Stdlib::Unixpath $base_path          = lookup('base_path', {default_value => '/srv/deployment'}),
    Array[String] $deployment_hosts      = lookup('deployment_hosts', {default_value => []}),
    Stdlib::Host $rsync_host             = lookup('profile::mediawiki::deployment::server::rsync_host'),
    Stdlib::Fqdn $releases_server        = lookup('releases_server'),
    Array[Stdlib::Fqdn] $other_releases_servers = lookup('releases_servers_failover'),
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

    # This is the scap2 master server setup, used to deploy mediawiki.
    class { '::scap::master':
        deployment_hosts => $deployment_hosts,
        deployment_group => $deployment_group,
    }

    class { '::scap::scripts':
        rsync_host  => $rsync_host,
        sql_scripts => 'present',
        statsd      => $statsd,
    }
    ## End scap2 config ###

    # Setup scap3 sources and server.
    # Create an instance of scap_source for each of the key specs in hiera.
    Scap::Source {
        base_path => $base_path,
    }

    $sources.each |$repo, $params| {
        scap::source { $repo:
            * => $params
        }
    }


    class {'::deployment::umask_wikidev': }

    class { '::deployment::deployment_server': }

    class {'::httpd': }

    # T298165
    class { '::git::daemon':
        directories => ['/srv/patches', '/srv/mediawiki-staging/private'],
        user        => 'mwdeploy',
        group       => $deployment_group,
    }

    ensure_packages('default-mysql-client')

    ferm::service { 'rsyncd_scap_master':
        proto  => 'tcp',
        port   => '873',
        srange => "(${deployable_networks_ferm})",
    }

    # T113351
    ferm::service { 'http_deployment_server':
        desc   => 'HTTP on deployment servers, for serving actual files to deploy',
        proto  => 'tcp',
        port   => '80',
        srange => "(${deployable_networks_ferm})",
    }

    # T298165
    $releases_servers = [ $releases_server ] + $other_releases_servers
    ferm::service { 'git-daemon':
        desc   => 'Git daemon',
        proto  => 'tcp',
        port   => '9418',
        srange => "(@resolve((${releases_servers.join(' ')})))",
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


    # This is symlink is accessed indirectly by
    # modules/profile/files/mediawiki/monitor_versions/check_mw_versions.py
    file { '/srv/deployment/mediawiki-staging':
        ensure  => link,
        target  => '/srv/mediawiki-staging',
        owner   => 'trebuchet',
        group   => $deployment_group,
        require => File['/srv/deployment'],
    }

    httpd::site { 'deployment':
        content => template('role/deployment/apache-vhost.erb'),
        require => File['/srv/deployment'],
    }

    # $secondary_deploy_ensure will be set to 'present' if we're
    # operating on an inactive/secondary deploy server.
    $secondary_deploy_ensure = $deployment_server ? {
        $::fqdn => 'absent',
        default => 'present'
    }

    class { '::deployment::rsync':
        deployment_server => $deployment_server,
        job_ensure        => $secondary_deploy_ensure,
        deployment_hosts  => $deployment_hosts,
    }

    motd::script { 'inactive_warning':
        ensure   => $secondary_deploy_ensure,
        priority => 1,
        content  => template('role/deployment/inactive.motd.erb'),
    }

    if $secondary_deploy_ensure == 'present' {
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

    # benchmarking tools (sessionstorage testing, k8s ml infra benchmarking) (T230178)
    ensure_packages(['siege', 'wrk', 'lua-cjson'])
}
