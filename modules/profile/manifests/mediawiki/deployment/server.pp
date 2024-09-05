# === Class profile::mediawiki::deployment::server
#
# Sets up scap and the corresponding apache site, and rsync daemon.
#
# The parameter "deployment_group" only refers to the group of people able to deploy mediawiki
# here, so to scap2 users. Scap3-related directories will be owned by wikidev unconditionally.
class profile::mediawiki::deployment::server(
    Stdlib::Fqdn $apache_fqdn                   = lookup('apache_fqdn', {default_value => $facts['fqdn']}),
    String $deployment_group                    = lookup('deployment_group'),
    Stdlib::Fqdn $deployment_server             = lookup('deployment_server'),
    Stdlib::Fqdn $main_deployment_server        = lookup('scap::deployment_server'),
    Stdlib::Unixpath $base_path                 = lookup('base_path', {default_value => '/srv/deployment'}),
    Array[Stdlib::Host] $deployment_hosts       = lookup('deployment_hosts', {default_value => []}),
    Stdlib::Host $rsync_host                    = lookup('profile::mediawiki::deployment::server::rsync_host'),
    Stdlib::Fqdn $releases_server               = lookup('releases_server'),
    Array[Stdlib::Fqdn] $other_releases_servers = lookup('releases_servers_failover'),
    String $statsd                              = lookup('statsd'),
    Hash[String, Struct[{
                        'origin'          => Optional[String],
                        'repository'      => Optional[String],
                        'scap_repository' => Optional[String]
    }]] $sources  = lookup('scap::sources'),
    Boolean $enable_auto_deploy                              = lookup('profile::mediawiki::deployment::server::enable_auto_deploy', {default_value => false}),
    Optional[Systemd::Timer::Datetime] $auto_deploy_interval = lookup('profile::mediawiki::deployment::server::auto_deploy_interval', {default_value => undef}),
    Optional[Systemd::Timer::Datetime] $auto_clean_interval  = lookup('profile::mediawiki::deployment::server::auto_clean_interval', {default_value => undef}),
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

    profile::auto_restarts::service { 'apache2': }
    profile::auto_restarts::service { 'envoyproxy': }

    # T298165
    class { '::git::daemon':
        directories => ['/srv/patches', '/srv/mediawiki-staging/private'],
        user        => 'mwdeploy',
        group       => $deployment_group,
    }

    ensure_packages('default-mysql-client')

    ferm::service { 'rsyncd_scap_master':
        proto  => 'tcp',
        port   => 873,
        srange => "(${deployable_networks_ferm})",
    }

    # T113351
    ferm::service { 'http_deployment_server':
        desc   => 'HTTP on deployment servers, for serving actual files to deploy',
        proto  => 'tcp',
        port   => 80,
        srange => "(${deployable_networks_ferm})",
    }

    # T298165
    $releases_servers = [ $releases_server ] + $other_releases_servers
    ferm::service { 'git-daemon':
        desc   => 'Git daemon',
        proto  => 'tcp',
        port   => 9418,
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

    file { '/usr/local/etc/fix-staging-perms.sh':
        content => "deployment_group=\"${deployment_group}\"\n",
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
    }

    # A command that group 'deployment' can execute to fix common file permission snafus
    # inside /srv/mediawiki-staging.
    file { '/usr/local/sbin/fix-staging-perms':
        mode    => '0555',
        source  => 'puppet:///modules/profile/mediawiki/deployment/fix-staging-perms.sh',
        owner   => 'root',
        group   => 'root',
        require => File['/usr/local/etc/fix-staging-perms.sh'],
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

    $primary_deploy_ensure = $deployment_server ? {
        $::fqdn => 'present',
        default => 'absent'
    }

    # $secondary_deploy_ensure will be set to 'present' if we're
    # operating on an inactive/secondary deploy server.
    $secondary_deploy_ensure = $deployment_server ? {
        $::fqdn => 'absent',
        default => 'present'
    }

    # Build array of deployment_hosts fqdn from array of ips and remove primary
    $deployment_hosts_fqdn = unique($deployment_hosts.map | $ip | { ipresolve($ip, 'ptr') }) - $deployment_server
    class { '::deployment::rsync':
        deployment_server => $deployment_server,
        deployment_hosts  => $deployment_hosts_fqdn,
    }

    motd::script { 'inactive_warning':
        ensure   => $secondary_deploy_ensure,
        priority => 1,
        content  => template('role/deployment/inactive.motd.erb'),
    }

    if $enable_auto_deploy {
        systemd::timer::job { 'train-presync':
            ensure                  => $primary_deploy_ensure,
            description             => 'Perform beginning-of-week train operations',
            user                    => 'mwpresync',
            command                 => '/usr/bin/scap stage-train -Dfull_image_build:True --yes auto',
            send_mail               => true,
            send_mail_only_on_error => false,
            send_mail_to            => 'releng@lists.wikimedia.org',
            interval                => {'start' => 'OnCalendar', 'interval' => $auto_deploy_interval},
            monitoring_enabled      => false,
            ignore_errors           => true,
        }
        systemd::timer::job { 'train-clean':
            ensure                  => $primary_deploy_ensure,
            description             => 'Clean up old train checkouts',
            user                    => 'mwpresync',
            command                 => '/usr/bin/scap clean auto',
            send_mail               => true,
            send_mail_only_on_error => false,
            send_mail_to            => 'releng@lists.wikimedia.org',
            interval                => {'start' => 'OnCalendar', 'interval' => $auto_clean_interval},
            monitoring_enabled      => false,
            ignore_errors           => true,
        }
    }

    # Bacula backups (T125527)
    backup::set { 'srv-deployment': }

    # tig is a ncurses-based git utility which is useful for
    #  determining the state of git repos during deployments.
    # git-review is useful for scap development/testing.
    ensure_packages(['percona-toolkit', 'tig', 'git-review'])

    # benchmarking tools (sessionstorage testing, k8s ml infra benchmarking) (T230178)
    ensure_packages(['siege', 'wrk', 'lua-cjson'])

    # Starting with git 2.30.3 (which also got backported to older releases
    # as CVE-2022-24765) git changed the default behaviour to add an ownership
    # check which prevents git operations by a user different than the one which
    # owns the .git directory within the repository. This also applies to the root
    # user and was added to git in
    # https://github.com/git/git/commit/8959555cee7ec045958f9b6dd62e541affb7e7d9
    # When making the change, git upstream added a new config directive 'safe.directory'
    # which omits the new safety check for a given directory.
    #
    # For Scap deployments in T330394, the scap provider was fixed to run all git
    # commands of the users owning the directory.
    #
    # However, for a shared environment like the deployment servers the safe.directory
    # option isn't well suited: It doesn't allow globbing and only operates on a single
    # directory and no sub directories within. Also allow-listing individual directories
    # would need an additional wrapper since deployers currently need to run individual
    # git commands. As such, for now we're disabling the new check globally until a better
    # fix is available
    git::systemconfig { 'disable-check-for-CVE-2022-24765':
        settings => {
            'safe' => {
                'directory' => '*',
            }
        }
    }
}
