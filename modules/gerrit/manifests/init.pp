# Manifest to setup a Gerrit instance
class gerrit(
    Stdlib::Fqdn                      $host,
    Stdlib::IP::Address::V4           $ipv4,
    Stdlib::Unixpath                  $java_home,
    Hash                              $ldap_config,

    String                            $config            = 'gerrit.config.erb',
    Boolean                           $enable_monitoring = true,
    Stdlib::Unixpath                  $git_dir           = '/srv/gerrit/git',
    Integer                           $git_open_files    = 20000,
    Stdlib::HTTPSUrl                  $gitiles_url       = "https://${::gerrit::host}/g",
    Stdlib::Datasize                  $heap_limit        = '32g',
    Array[Stdlib::Fqdn]               $replica_hosts     = [],
    Boolean                           $replica           = false,
    Hash[String, Hash]                $replication       = {},
    String                            $ssh_host_key      = 'ssh_host_key',
    Boolean                           $use_acmechief     = false,
    Stdlib::HTTPSUrl                  $url               = "https://${::gerrit::host}/r",

    Optional[Stdlib::IP::Address::V6] $ipv6              = undef,
    Optional[String]                  $scap_user         = undef,
    Optional[String]                  $scap_key_name     = undef,
) {

    class { 'gerrit::jobs': }

    group { 'gerrit2':
        ensure => present,
    }

    # TODO convert to systemd::sysuser
    user { 'gerrit2':
        ensure     => 'present',
        gid        => 'gerrit2',
        shell      => '/bin/bash',
        home       => '/var/lib/gerrit2',
        system     => true,
        managehome => true,
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

    scap::target { 'gerrit/gerrit':
        deploy_user => $scap_user,
        manage_user => false,
        key_name    => $scap_key_name,
    }

    scap::target { 'gervert/deploy':
        deploy_user => $scap_user,
        manage_user => false,
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
        owner  => $scap_user,
        group  => $scap_user,
        mode   => '0775',
    }

    file { '/var/lib/gerrit2':
        ensure  => directory,
        recurse => 'remote',
        mode    => '0755',
        owner   => $scap_user,
        group   => $scap_user,
        source  => 'puppet:///modules/gerrit/homedir',
    }
    # We no more use custom log4j config
    file { '/var/lib/gerrit2/review_site/etc/log4j.xml':
        ensure => absent,
    }

    file { '/var/lib/gerrit2/review_site/bin':
        ensure => directory,
        owner  => $scap_user,
        group  => $scap_user,
        mode   => '0775',
    }

    # Since Gerrit 3.3 we are using gerrit-theme.js
    file { '/var/lib/gerrit2/review_site/static/gerrit-theme.html':
        ensure => absent,
    }

    file { '/var/lib/gerrit2/review_site/tmp':
        ensure => directory,
        owner  => $scap_user,
        group  => $scap_user,
        mode   => '0700',
    }

    file { '/var/lib/gerrit2/review_site/bin/gerrit.war':
      ensure  => 'link',
      target  => '/srv/deployment/gerrit/gerrit/gerrit.war',
      require => Scap::Target['gerrit/gerrit'],
    }

    file { '/var/lib/gerrit2/.ssh/id_rsa':
        owner     => $scap_user,
        group     => $scap_user,
        mode      => '0400',
        content   => secret('gerrit/id_rsa'),
        show_diff => false,
    }

    ssh::userkey { 'gerrit2-scap':
        ensure  => present,
        user    => $scap_user,
        skey    => 'gerrit-scap',
        content => secret('keyholder/gerrit.pub'),
    }

    file { '/var/lib/gerrit2/review_site/lib':
        ensure => directory,
        owner  => $scap_user,
        group  => $scap_user,
        mode   => '0555',
    }

    # The various configuration files
    file {
        default:
            owner => $scap_user,
            group => $scap_user,
            mode  => '0444';
        '/var/lib/gerrit2/review_site/etc/gerrit.config':
            content => template("gerrit/${config}");
        '/var/lib/gerrit2/review_site/etc/gitiles.config':
            content => template('gerrit/gitiles.config.erb');
        '/var/lib/gerrit2/review_site/etc/lfs.config':
            content => template('gerrit/lfs.config.erb');
    }

    file { '/var/lib/gerrit2/review_site/etc/its/templates':
        ensure  => directory,
        source  => 'puppet:///modules/gerrit/its/',
        recurse => true,
        purge   => true,
        owner   => $scap_user,
        group   => $scap_user,
        mode    => '0444',
        require => File['/var/lib/gerrit2'],
    }

    file { '/var/lib/gerrit2/review_site/etc/secure.config':
        content => template('gerrit/secure.config.erb'),
        owner   => $scap_user,
        group   => $scap_user,
        mode    => '0440',
    }

    file { '/var/lib/gerrit2/review_site/etc/motd.config':
        ensure => 'link',
        target => '/srv/deployment/gerrit/gerrit/etc/motd.config',
    }

    if $ssh_host_key != undef {
        file { '/var/lib/gerrit2/review_site/etc/ssh_host_key':
            ensure    => present,
            content   => secret("gerrit/${ssh_host_key}"),
            owner     => $scap_user,
            group     => $scap_user,
            mode      => '0440',
            show_diff => false,
        }
    }

    file { '/var/lib/gerrit2/review_site/etc/replication.config':
        ensure  => stdlib::ensure(!$replica, 'file'),
        content => template('gerrit/replication.config.erb'),
        owner   => $scap_user,
        group   => $scap_user,
        mode    => '0444',
    }

    file { '/var/lib/gerrit2/review_site/logs':
        ensure  => 'link',
        target  => '/var/log/gerrit',
        owner   => $scap_user,
        group   => $scap_user,
        require => [Scap::Target['gerrit/gerrit'], File['/var/log/gerrit']],
    }

    file { '/var/log/gerrit':
        ensure => directory,
        owner  => $scap_user,
        group  => $scap_user,
        mode   => '0755',
    }

    file { '/var/lib/gerrit2/review_site/plugins':
      ensure  => 'link',
      target  => '/srv/deployment/gerrit/gerrit/plugins',
      require => Scap::Target['gerrit/gerrit'],
    }

    systemd::service { 'gerrit':
        ensure         => present,
        content        => systemd_template('gerrit'),
        service_params => {
            ensure   => 'running',
        },
    }

    file { '/etc/gerrit':
        ensure => link,
        target => '/var/lib/gerrit2/review_site/etc',
    }

    file { '/etc/default/gerrit':
        content => template('gerrit/gerrit.default.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    file { '/etc/default/gerritcodereview':
        ensure  => 'link',
        target  => '/etc/default/gerrit',
        require => File['/etc/default/gerrit'],
    }

    if $enable_monitoring {
        nrpe::monitor_service { 'gerrit':
            ensure       => 'present',
            description  => 'gerrit process',
            nrpe_command => "/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 --ereg-argument-array '^${java_home}/bin/java .*-jar /var/lib/gerrit2/review_site/bin/gerrit.war daemon -d /var/lib/gerrit2/review_site'",
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Gerrit',
        }
    }
}
