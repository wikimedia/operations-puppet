# Manifest to setup a Gerrit instance
#
# @param daemon_user Unix user running the Gerrit daemon
# @param scap_user Unix user for deployment
class gerrit(
    Stdlib::Fqdn                      $host,
    Stdlib::IP::Address::V4           $ipv4,
    Stdlib::Unixpath                  $java_home,
    Hash                              $ldap_config,
    String                            $daemon_user,
    String                            $scap_user,

    String                            $config            = 'gerrit.config.erb',
    Boolean                           $enable_monitoring = true,
    Stdlib::Unixpath                  $git_dir           = '/srv/gerrit/git',
    Integer                           $git_open_files    = 20000,
    Stdlib::HTTPSUrl                  $gitiles_url       = "https://${::gerrit::host}/g",
    Stdlib::Datasize                  $heap_limit        = '32g',
    Boolean                           $manage_scap_user  = false,
    Array[Stdlib::Fqdn]               $replica_hosts     = [],
    Boolean                           $replica           = false,
    Hash[String, Hash]                $replication       = {},
    String                            $ssh_host_key      = 'ssh_host_key',
    Boolean                           $use_acmechief     = false,
    Stdlib::HTTPSUrl                  $url               = "https://${::gerrit::host}/r",

    Optional[Stdlib::IP::Address::V6] $ipv6              = undef,
    Optional[String]                  $scap_key_name     = undef,
) {

    $home_dir = "/var/lib/${daemon_user}"
    $gerrit_site = "${home_dir}/review_site"

    class { 'gerrit::jobs': }

    group { 'gerrit2':
        ensure => present,
    }

    # TODO convert to systemd::sysuser
    user { 'gerrit2':
        ensure     => 'present',
        gid        => 'gerrit2',
        shell      => '/bin/bash',
        home       => $home_dir,
        system     => true,
        managehome => true,
    }

    file { $home_dir:
        ensure  => directory,
        recurse => 'remote',
        mode    => '0755',
        owner   => $daemon_user,
        group   => $daemon_user,
        source  => 'puppet:///modules/gerrit/homedir',
    }

    # Private config
    $email_key = $passwords::gerrit::gerrit_email_key
    $phab_token = $passwords::gerrit::gerrit_phab_token
    $prometheus_bearer_token = $passwords::gerrit::prometheus_bearer_token

    $ldap_host = $ldap_config['ro-server']
    $ldap_base_dn = $ldap_config['base-dn']

    $java_options = [
        '-XX:+UseG1GC',
        "-Xmx${heap_limit} -Xms${heap_limit}",
        '-Dflogger.backend_factory=com.google.common.flogger.backend.log4j.Log4jBackendFactory#getInstance',
        '-Dflogger.logging_context=com.google.gerrit.server.logging.LoggingContext#getInstance',
        # These settings apart from the bottom control logging for gc
        '-XX:+UnlockExperimentalVMOptions',
        '-XX:G1NewSizePercent=15',
        '-XX:+UseStringDeduplication',
        # Whenever we run out of heap space, we want a full snapshot in order
        # to investigate.
        '-XX:+HeapDumpOnOutOfMemoryError',
        # The JVM most probably can't recover, hence exit.
        '-XX:+ExitOnOutOfMemoryError',
        '-XX:HeapDumpPath=/srv/gerrit',
    ]

    ensure_packages([
        'python3',
        'python3-virtualenv',
        'virtualenv',
        'python3-pip'
    ])

    ssh::userkey { 'gerrit2-scap':
        ensure  => present,
        user    => $scap_user,
        skey    => 'gerrit-scap',
        content => secret('keyholder/gerrit.pub'),
    }

    scap::target { 'gerrit/gerrit':
        deploy_user => $scap_user,
        manage_user => $manage_scap_user,
        key_name    => $scap_key_name,
    }

    scap::target { 'gervert/deploy':
        deploy_user => $scap_user,
        manage_user => $manage_scap_user,
        key_name    => $scap_key_name,
    }

    file { [
        '/srv/gerrit',
        '/srv/gerrit/jvmlogs',
        '/srv/gerrit/git',
        '/srv/gerrit/plugins',
        '/srv/gerrit/plugins/lfs',
    ]:
        ensure => directory,
        owner  => $daemon_user,
        group  => $daemon_user,
        mode   => '0775',
    }

    # We no more use custom log4j config
    file { "${gerrit_site}/etc/log4j.xml":
        ensure => absent,
    }

    # Gerrit init installs a few bin helper
    file { "${gerrit_site}/bin":
        ensure => directory,
        owner  => $daemon_user,
        group  => $daemon_user,
        mode   => '0775',
    }
    # Make sure we use our targetted version rather than the one copied on init
    file { "${gerrit_site}/bin/gerrit.war":
      ensure  => 'link',
      target  => '/srv/deployment/gerrit/gerrit/gerrit.war',
      require => Scap::Target['gerrit/gerrit'],
    }

    file { "${gerrit_site}/tmp":
        ensure => directory,
        owner  => $daemon_user,
        group  => $daemon_user,
        mode   => '0700',
    }

    file { "${home_dir}/.ssh/id_rsa":
        owner     => $daemon_user,
        group     => $daemon_user,
        mode      => '0400',
        content   => secret('gerrit/id_rsa'),
        show_diff => false,
    }

    # Created by gerrit init. If we ever use it, it should be a symlink to
    # /srv/deployment/gerrit/gerrit/lib and be owned by root.
    file { "${gerrit_site}/lib":
        ensure => directory,
        owner  => $daemon_user,
        group  => $daemon_user,
        mode   => '0555',
    }

    # The various configuration files
    #
    # Those are fully managed by Puppet but the Gerrit daemon might try to
    # amend them on boot (notably gerrit.config). Any change happening this
    # way should be reflected back to Puppet.
    #
    # TODO maybe mark them root owned to prevent Gerrit to write to them, but
    # it might then refuse to start.
    file {
        default:
            owner => $daemon_user,
            group => $daemon_user,
            mode  => '0444';
        "${gerrit_site}/etc/gerrit.config":
            content => template("gerrit/${config}");
        "${gerrit_site}/etc/gitiles.config":
            content => template('gerrit/gitiles.config.erb');
        "${gerrit_site}/etc/lfs.config":
            content => template('gerrit/lfs.config.erb');
    }

    # For the replication plugin.
    #
    # TODO maybe mark it root owned to prevent Gerrit to write to it, but
    # it might then refuse to start.
    file { "${gerrit_site}/etc/replication.config":
        ensure  => stdlib::ensure(!$replica, 'file'),
        content => template('gerrit/replication.config.erb'),
        owner   => $daemon_user,
        group   => $daemon_user,
        mode    => '0444',
    }

    # Templates used for Phabricator notifications
    #
    # Those are static files and should ultimately be migrated to the Gerrit
    # deploy repository, the directory would then become a symlink to
    # /srv/deployment/gerrit/gerrit/etc/its/templates and owned by root.
    file { "${gerrit_site}/etc/its/templates":
        ensure  => directory,
        source  => 'puppet:///modules/gerrit/its/',
        recurse => true,
        purge   => true,
        owner   => root,
        group   => root,
        mode    => '0444',
    }

    # Fully managed by Puppet
    file { "${gerrit_site}/etc/secure.config":
        content => template('gerrit/secure.config.erb'),
        owner   => $daemon_user,
        group   => $daemon_user,
        mode    => '0440',
    }

    # Used by the motd plugin which lets one send a message when ones sends a
    # a review. We never used it and might consider dropping the plugin and
    # ths this file as well.
    file { "${gerrit_site}/etc/motd.config":
        ensure => 'link',
        target => '/srv/deployment/gerrit/gerrit/etc/motd.config',
    }

    if $ssh_host_key != undef {
        file { "${gerrit_site}/etc/ssh_host_key":
            ensure    => present,
            content   => secret("gerrit/${ssh_host_key}"),
            owner     => $daemon_user,
            group     => $daemon_user,
            mode      => '0440',
            show_diff => false,
        }
    }

    file { '/var/log/gerrit':
        ensure => directory,
        owner  => $daemon_user,
        group  => $daemon_user,
        mode   => '0755',
    }

    file { "${gerrit_site}/logs":
        ensure  => 'link',
        target  => '/var/log/gerrit',
        owner   => $daemon_user,
        group   => $daemon_user,
        require => Scap::Target['gerrit/gerrit'],
    }

    file { "${gerrit_site}/plugins":
      ensure  => 'link',
      target  => '/srv/deployment/gerrit/gerrit/plugins',
      require => Scap::Target['gerrit/gerrit'],
    }

    systemd::service { 'gerrit':
        ensure  => present,
        content => systemd_template('gerrit'),
    }

    # EnvironmentFile sourced by the systemd service
    file { '/etc/default/gerrit':
        content => template('gerrit/gerrit.default.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    # Legacy default, probably no more used (2022-09-14)
    file { '/etc/default/gerritcodereview':
        ensure => 'link',
        target => '/etc/default/gerrit',
    }

    # Convenience link to $GERRIT_SITE/etc
    file { '/etc/gerrit':
        ensure => link,
        target => "${gerrit_site}/etc",
    }

    if $enable_monitoring {
        nrpe::monitor_service { 'gerrit':
            ensure       => 'present',
            description  => 'gerrit process',
            nrpe_command => "/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 --ereg-argument-array '^${java_home}/bin/java .*-jar ${gerrit_site}/bin/gerrit.war daemon -d ${gerrit_site}'",
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Gerrit',
        }
    }
}
