# == Class role::wikimetrics
# Installs and hosts wikimetrics.
# NOTE:  This class does not (yet) work in production!
#
# role::wikimetrics requires class passwords::wikimetrics to
# exist and populated with variables.
# passwords::wikimetrics is not a real class checked in to any repository.
# In labs on your self hosted puppetmaster, you must do two
# things to make this exist:
# 1. Edit /var/lib/git/operations/puppet/manifests/passwords.pp
#    and add this class with the variables below.
# 2. Edit /var/lib/git/operations/puppet/manifests/site.pp
#    and add an 'import "passwords.pp" line near the top.
#
# == Globals
# These parameters can be set globally or via wikitech.
# $wikimetrics_web_mode       - Either 'apache' or 'daemon'. If apache,
#                               wikimetrics will be run in WSGI.  If
#                               daemon, wikimetrics will be managed
#                               as a python daemon process via upstart.
#                               Default: apache
# $wikimetrics_ssl_redirect   - If true, apache will force redirect any
#                               requests made to https:://$server_name...
#                               This does nothing if you are running in
#                               daemon mode.  Default: false
# $wikimetrics_server_name    - Apache ServerName.  This is not used if
#                               $web_mode is daemon.  Default: $::fqdn
# $wikimetrics_server_aliases - comma separated list of Apache ServerAlias-es.
#                               Default: undef
# $wikimetrics_server_port    - port on which to listen for wikimetrics web requests.
#                               If in apache mode, this defaults to 80, else
#                               this defaults to 5000.
# $wikimetrics_backup         - If it the evaluates to true, backup gets set up.
#                               Otherwise, backup gets turned off.
#
class role::wikimetrics {
    # wikimetrics does not yet run via puppet in production
    if $::realm == 'production' {
        fail('Cannot include role::wikimetrics in production (yet).')
    }

    include passwords::wikimetrics

    $wikimetrics_path = '/srv/wikimetrics'

    # Wikimetrics Database Creds
    $db_user_wikimetrics   = $::passwords::wikimetrics::db_user_wikimetrics
    $db_pass_wikimetrics   = $::passwords::wikimetrics::db_pass_wikimetrics
    $db_host_wikimetrics   = 'localhost'
    $db_name_wikimetrics   = 'wikimetrics'

    # Centralauth Database Creds
    $db_user_centralauth   = $::passwords::wikimetrics::db_user_labsdb
    $db_pass_centralauth   = $::passwords::wikimetrics::db_pass_labsdb
    $db_host_centralauth   = 'labsdb1001.eqiad.wmnet'
    $db_name_centralauth   = 'centralauth_p'

    # Use the LabsDB for editor cohort analysis
    $db_user_mediawiki     = $::passwords::wikimetrics::db_user_labsdb
    $db_pass_mediawiki     = $::passwords::wikimetrics::db_pass_labsdb
    $db_host_mediawiki     = 'labsdb1001.eqiad.wmnet'
    $db_name_mediawiki     = '{0}_p'

    # OAuth and Google Auth
    $flask_secret_key      = $::passwords::wikimetrics::flask_secret_key
    $google_client_id      = $::passwords::wikimetrics::google_client_id
    $google_client_email   = $::passwords::wikimetrics::google_client_email
    $google_client_secret  = $::passwords::wikimetrics::google_client_secret
    $meta_mw_consumer_key  = $::passwords::wikimetrics::meta_mw_consumer_key
    $meta_mw_client_secret = $::passwords::wikimetrics::meta_mw_client_secret

    # base directory settings

    # We keep vardir under /srv so that wikimetrics
    # has enough space to write files.
    $var_directory       = '/srv/var/wikimetrics'
    $public_subdirectory = 'public'
    $public_directory    = "${var_directory}/${public_subdirectory}"

    # Run as daemon python process or in Apache WSGI.
    $web_mode = $::wikimetrics_web_mode ? {
        undef   => 'apache',
        default => $::wikimetrics_web_mode,
    }
    $wikimetrics_user = 'wikimetrics'
    # Make wikimetrics group 'www-data' if running in apache mode.
    # This allows for apache to write files to wikimetrics var directories.
    $wikimetrics_group = $web_mode ? {
        'apache' => 'www-data',
        default  => 'wikimetrics',
    }


    # if the global variable $::wikimetrics_server_name is set,
    # use it as the server_name.  This allows
    # configuration via the Labs Instance configuration page.
    $server_name = $::wikimetrics_server_name ? {
        undef   => $::fqdn,
        default => $::wikimetrics_server_name,
    }
    $server_aliases = $::wikimetrics_server_aliases ? {
        undef   => undef,
        default => split($::wikimetrics_server_aliases, ','),
    }

    $server_port = $::wikimetrics_server_port ? {
        # If $::wikimetrics_server_port is not set,
        # default to port 80 for apache web mode,
        # or port 5000 for daemon web mode.
        undef   => $web_mode ? {
            'apache' => 80,
            default  => 5000,
        },
        default => $::wikimetrics_server_port,
    }
    $ssl_redirect = $::wikimetrics_ssl_redirect ? {
        undef   => false,
        default => $::wikimetrics_ssl_redirect,
    }

    # If the global variable $::wikimetrics_debug is set, then
    # use it.  Otherwise, default to true.
    $debug = $::wikimetrics_debug ? {
        undef   => true,
        default => $::wikimetrics_debug,
    }

    $celery_concurrency = $debug ? {
        true  => 16,
        # Run at 24 concurrency in non debug environments.
        false => 24,
    }

    $db_pool_wikimetrics = $debug ? {
        true  => 20,
        # Run at 100 concurrency in non debug environments.
        false => 100,
    }

    $db_pool_mediawiki = $debug ? {
        true  => 32,
        # Run at 200 concurrency in non debug environments.
        false => 200,
    }

    # need pip :/
    if !defined(Package['python-pip']) {
        package { 'python-pip':
            ensure => 'installed',
        }
    }
    # Put data on /srv so it has room to grow
    include role::labs::lvm::srv

    # Make sure /srv/var exists.
    # The wikimetrics module will manage $var_directory.
    if !defined(File['/srv/var']) {
        file { '/srv/var':
            ensure  => 'directory',
            mode    => '0755',
            owner   => 'root',
            group   => 'root',
            require => Labs_lvm::Volume['second-local-disk'],
            before  => Class['::wikimetrics'],
        }
    }


    # Setup mysql, put data in /srv
    class { 'mysql::server':
        config_hash => {
            'datadir' => '/srv/mysql'
        },
        before      => Class['::wikimetrics::database'],
        require     => Labs_lvm::Volume['second-local-disk']
    }

    class { '::wikimetrics':
        path                         => $wikimetrics_path,
        user                         => $wikimetrics_user,
        group                        => $wikimetrics_group,

        # clone wikimetrics as root user so it can write to /srv
        repository_owner             => 'root',

        debug                        => $debug,

        server_name                  => $server_name,
        server_aliases               => $server_aliases,
        server_port                  => $server_port,
        ssl_redirect                 => $ssl_redirect,
        celery_concurrency           => $celery_concurrency,

        flask_secret_key             => $flask_secret_key,
        google_client_id             => $google_client_id,
        google_client_email          => $google_client_email,
        google_client_secret         => $google_client_secret,
        meta_mw_consumer_key         => $meta_mw_consumer_key,
        meta_mw_client_secret        => $meta_mw_client_secret,

        db_user_wikimetrics          => $db_user_wikimetrics,
        db_pass_wikimetrics          => $db_pass_wikimetrics,
        db_host_wikimetrics          => $db_host_wikimetrics,
        db_name_wikimetrics          => $db_name_wikimetrics,
        db_pool_wikimetrics          => $db_pool_wikimetrics,

        db_user_centralauth          => $db_user_centralauth,
        db_pass_centralauth          => $db_pass_centralauth,
        db_host_centralauth          => $db_host_centralauth,
        db_name_centralauth          => $db_name_centralauth,

        db_user_mediawiki            => $db_user_mediawiki,
        db_pass_mediawiki            => $db_pass_mediawiki,
        db_host_mediawiki            => $db_host_mediawiki,
        db_name_mediawiki            => $db_name_mediawiki,
        db_pool_mediawiki            => $db_pool_mediawiki,
        db_replication_lag_dbs       => [
            'enwiki', # s1
            'eowiki', # s2
            'elwiki', # s3
            'commonswiki', # s4
            'dewiki', # s5
            'frwiki', # s6
            'eswiki', # s7
        ],
        db_replication_lag_threshold => 3,

        # wikimetrics runs on the LabsDB usually,
        # where the archive and revision tables have _userindex variants
        # These are preferable to use for performance reasons
        revision_tablename           => 'revision_userindex',
        archive_tablename            => 'archive_userindex',

        var_directory                => $var_directory,
        public_subdirectory          => $public_subdirectory,

        require                      => Labs_lvm::Volume['second-local-disk'],
    }

    # Run the wikimetrics/scripts/install script
    # in order to pip install proper dependencies.
    # Note:  This is not in the wikimetrics puppet module
    # because it is an improper way to do things in
    # WMF production.
    exec { 'install_wikimetrics_dependencies':
        command => "${wikimetrics_path}/scripts/install ${wikimetrics_path}",
        creates => '/usr/local/bin/wikimetrics',
        path    => '/usr/local/bin:/usr/bin:/bin',
        user    => 'root',
        require => [Package['python-pip'], Class['::wikimetrics']],
    }

    class { '::wikimetrics::database':
        require => Exec['install_wikimetrics_dependencies'],
    }

    # The redis module by default sets up redis in /a.  Oh well!
    if !defined(File['/a']) {
        file { '/a':
            ensure => directory,
            before => Class['::wikimetrics::queue']
        }
    }

    # Install redis and use a custom config template.
    # Wikimetrics needs redis to save data for longer
    # than the default redis.conf.erb template allows.
    $redis_dir        = '/a/redis'
    $redis_dbfilename = "${hostname}-6379.rdb"


    redis::instance { 6379:
        settings => {
            dbfilename                  => "${::hostname}-${port}.rdb",
            dir                         => '/srv/redis',
            maxmemory                   => '1Gb',
            maxmemory_policy            => 'volatile-lru',
            maxmemory_samples           => 5,
            no_appendfsync_on_rewrite   => true,
            save                        => '60 20',
            slave_read_only             => false,
        },
    }

    # TODO: Support installation of queue, web and database
    # classes on different nodes (maybe?).
    class { '::wikimetrics::queue':
        require => [
            Exec['install_wikimetrics_dependencies'],
        ],
    }

    class { '::wikimetrics::web':
        mode    => $web_mode,
        require => Exec['install_wikimetrics_dependencies'],
    }

    class { '::wikimetrics::scheduler':
        require => Exec['install_wikimetrics_dependencies'],
    }

    # backup regardless of whether we are in debug mode or not
    if $::wikimetrics_backup {
      $backup_ensure = 'present'
    } else {
      $backup_ensure = 'absent'
    }
    class { '::wikimetrics::backup':
        ensure        => $backup_ensure,
        destination   => "/data/project/wikimetrics/backup/${::hostname}",
        db_user       => $db_user_wikimetrics,
        db_pass       => $db_pass_wikimetrics,
        db_name       => $db_name_wikimetrics,
        db_host       => $db_host_wikimetrics,
        redis_db_file => "${redis_dir}/${redis_dbfilename}",
        public_files  => $public_directory,
        keep_days     => 10,
    }

    # Get aggregated projectcounts files from git repo
    # Note that this repo is for legacy projectcounts
    # It should be analytics/aggregator/projectcounts/data.git
    # but we keep it as is from legacy.
    $aggregator_projectcounts_data_directory = '/srv/aggregator-projectcounts-data'
    git::clone { 'aggregator_projectcounts_data':
        ensure    => 'latest',
        directory => $aggregator_projectcounts_data_directory,
        origin    => 'https://gerrit.wikimedia.org/r/p/analytics/aggregator/data.git',
        owner     => $wikimetrics_user,
        group     => $wikimetrics_group,
    }

    # Get aggregated projectview files from git repo
    $aggregator_projectview_data_directory = '/srv/aggregator-projectview-data'
    git::clone { 'aggregator_projectview_data':
        ensure    => 'latest',
        directory => $aggregator_projectview_data_directory,
        origin    => 'https://gerrit.wikimedia.org/r/p/analytics/aggregator/projectview/data.git',
        owner     => $wikimetrics_user,
        group     => $wikimetrics_group,
    }

    # Create public datafiles folder
    file { "${public_directory}/datafiles":
        ensure  => 'directory',
        owner   => $wikimetrics_user,
        group   => $wikimetrics_group,
        require => File[$public_directory],
    }

    # Link public DailyPageviews_legacy folder to aggregator_projectcounts_data folder
    file { "${public_directory}/datafiles/LegacyPageviews":
        ensure  => 'link',
        target  => "${aggregator_projectcounts_data_directory}/projectcounts/daily",
        owner   => $wikimetrics_user,
        group   => $wikimetrics_group,
        require => File["${public_directory}/datafiles"]
    }

    # Link public DailyPageviews folder to aggregator_projectview_data folder
    file { "${public_directory}/datafiles/Pageviews":
        ensure  => 'link',
        target  => "${aggregator_projectview_data_directory}/projectview/daily",
        owner   => $wikimetrics_user,
        group   => $wikimetrics_group,
        require => File["${public_directory}/datafiles"]
    }

    # Using logster to send wikimetrics stats to statsd -> graphite.
    # hardcoded labs statsdhost: labmon1001.eqiad.wmnet
    # crontab should run once a day at 23 hours
    if !$debug {
        logster::job { 'wikimetrics-apache-requests':
            minute          => '0',
            hour            => '23',
            parser          => 'LineCountLogster',
            logfile         => '/var/log/apache2/access.wikimetrics.log',
            logster_options => "-o statsd --statsd-host=labmon1001.eqiad.wmnet:8125 --metric-prefix='analytics.wikimetrics.requests.ui' --parser-options '--regex=.*(report|cohort|metrics|login|about|contact).*'"
        }

        logster::job { 'wikimetrics-number-of-successful-reports':
            minute          => '10',
            hour            => '23',
            parser          => 'LineCountLogster',
            logfile         => '/var/log/apache2/access.wikimetrics.log',
            logster_options => "-o statsd --statsd-host=labmon1001.eqiad.wmnet:8125 --metric-prefix='analytics.wikimetrics.successful_reports' --parser-options '--regex=.* succeeded .*'"
        }
    }
}
