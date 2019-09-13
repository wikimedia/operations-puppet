# sets up jetty for gerrit
# https://projects.eclipse.org/projects/rt.jetty/developer
class gerrit::jetty(
    Stdlib::Fqdn $host,
    Stdlib::Ipv4 $ipv4,
    Optional[Stdlib::Ipv6] $ipv6,
    Stdlib::Fqdn $db_host = 'localhost',
    Array[Stdlib::Fqdn] $replica_hosts = [],
    Hash $replication = {},
    Stdlib::HTTPSUrl $url = "https://${::gerrit::host}/r",
    Stdlib::HTTPSUrl $gitiles_url = "https://${::gerrit::host}/g",
    String $db_name = 'reviewdb',
    String $db_user = 'gerrit',
    String $git_dir = 'git',
    Optional[String] $ssh_host_key = undef,
    String $heap_limit = '32g',
    Boolean $replica = false,
    Stdlib::Unixpath $java_home = '/usr/lib/jvm/java-8-openjdk-amd64/jre',
    String $config = 'gerrit.config.erb',
    Integer $git_open_files = 20000,
    String $smtp_encryption = 'none',
    Optional[Hash] $ldap_config = undef,
    # You must also change $java_home when changing versions.
    Enum['11', '8'] $java_version = '8',
    Optional[String] $scap_user = undef,
    Optional[String] $scap_key_name = undef,
    ) {

    group { 'gerrit2':
        ensure => present,
    }

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
    $db_pass = $passwords::gerrit::gerrit_db_pass
    $phab_token = $passwords::gerrit::gerrit_phab_token
    $prometheus_bearer_token = $passwords::gerrit::prometheus_bearer_token

    $ldap_host = $ldap_config['ro-server']
    $ldap_base_dn = $ldap_config['base-dn']

    if $replica {
        $sshd_host = $replica_hosts[0]
    } else {
        $sshd_host = $host
    }

    $java_options = [
        '-XX:+UseG1GC',
        "-Xmx${heap_limit} -Xms${heap_limit}",
        '-Dflogger.backend_factory=com.google.common.flogger.backend.log4j.Log4jBackendFactory#getInstance',
        '-Dlog4j.configuration=file:///var/lib/gerrit2/review_site/etc/log4j.xml',
        # These settings apart from the bottom control logging for gc
        '-Xloggc:/srv/gerrit/jvmlogs/jvm_gc.%p.log',
        '-XX:+UnlockExperimentalVMOptions',
        '-XX:G1NewSizePercent=15',
        '-XX:+UseStringDeduplication',
        '-XX:+PrintGCApplicationStoppedTime',
        '-XX:+PrintGCDetails',
        '-XX:+PrintGCDateStamps',
        '-XX:+PrintTenuringDistribution',
        '-XX:+PrintGCCause',
        '-XX:+UseGCLogFileRotation',
        '-XX:NumberOfGCLogFiles=10',
        '-XX:GCLogFileSize=2M',
    ]

    if $java_version == '11' {
        require_package('openjdk-11-jdk')
        require_package('openjdk-11-dbg')
    } else {
        apt::repository { 'wikimedia-openjdk8':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => 'buster-wikimedia',
            components => 'component/jdk8',
            notify     => Exec['apt_update_jdk8'],
        }

        # First installs can trip without this
        exec {'apt_update_jdk8':
            command     => '/usr/bin/apt-get update',
            refreshonly => true,
            logoutput   => true,
        }

        package { 'openjdk-8-jdk':
            ensure  => present,
            require => Apt::Repository['wikimedia-openjdk8'],
        }
        package { 'openjdk-8-dbg':
            ensure  => present,
            require => Apt::Repository['wikimedia-openjdk8'],
        }
    }

    require_package([
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

    file { '/srv/gerrit':
        ensure => directory,
        owner  => $scap_user,
        group  => $scap_user,
        mode   => '0664',
    }

    file { '/srv/gerrit/jvmlogs':
        ensure  => directory,
        owner   => $scap_user,
        group   => $scap_user,
        mode    => '0664',
        require => File['/srv/gerrit'],
    }

    file { '/srv/gerrit/git':
        ensure  => directory,
        owner   => $scap_user,
        group   => $scap_user,
        mode    => '0775',
        require => File['/srv/gerrit'],
    }

    file { '/srv/gerrit/plugins':
        ensure  => directory,
        owner   => $scap_user,
        group   => $scap_user,
        mode    => '0775',
        require => File['/srv/gerrit'],
    }

    file { '/srv/gerrit/plugins/lfs':
        ensure  => directory,
        owner   => $scap_user,
        group   => $scap_user,
        mode    => '0775',
        require => File['/srv/gerrit/plugins'],
    }

    file { '/var/lib/gerrit2':
        ensure  => directory,
        recurse => 'remote',
        mode    => '0755',
        owner   => $scap_user,
        group   => $scap_user,
        source  => 'puppet:///modules/gerrit/homedir',
    }

    file { '/var/lib/gerrit2/review_site/bin':
        ensure  => directory,
        owner   => $scap_user,
        group   => $scap_user,
        mode    => '0775',
        require => File['/var/lib/gerrit2'],
    }

    file { '/var/lib/gerrit2/review_site/tmp':
        ensure  => directory,
        owner   => $scap_user,
        group   => $scap_user,
        mode    => '0700',
        require => File['/var/lib/gerrit2'],
    }

    file { '/var/lib/gerrit2/review_site/bin/gerrit.war':
      ensure  => 'link',
      target  => '/srv/deployment/gerrit/gerrit/gerrit.war',
      require => [File['/var/lib/gerrit2'], Scap::Target['gerrit/gerrit']],
    }

    file { '/var/lib/gerrit2/.ssh/id_rsa':
        owner     => $scap_user,
        group     => $scap_user,
        mode      => '0400',
        require   => File['/var/lib/gerrit2'],
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
        ensure  => directory,
        owner   => $scap_user,
        group   => $scap_user,
        mode    => '0555',
        require => File['/var/lib/gerrit2'],
    }

    file { '/var/lib/gerrit2/review_site/lib/javamelody-deps_deploy.jar':
        ensure  => 'link',
        target  => '/srv/deployment/gerrit/gerrit/lib/javamelody-deps_deploy.jar',
        require => [File['/var/lib/gerrit2/review_site/lib'], Scap::Target['gerrit/gerrit']],
    }

    file { '/var/lib/gerrit2/review_site/etc/gerrit.config':
        content => template("gerrit/${config}"),
        owner   => $scap_user,
        group   => $scap_user,
        mode    => '0444',
        require => File['/var/lib/gerrit2'],
    }

    file { '/var/lib/gerrit2/review_site/etc/gitiles.config':
        content => template('gerrit/gitiles.config.erb'),
        owner   => $scap_user,
        group   => $scap_user,
        mode    => '0444',
        require => File['/var/lib/gerrit2'],
    }

    file { '/var/lib/gerrit2/review_site/etc/lfs.config':
        content => template('gerrit/lfs.config.erb'),
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
        require => File['/var/lib/gerrit2'],
    }

    file { '/var/lib/gerrit2/review_site/etc/motd.config':
        ensure  => 'link',
        target  => '/srv/deployment/gerrit/gerrit/etc/motd.config',
        require => File['/var/lib/gerrit2'],
    }

    file { '/var/lib/gerrit2/review_site/etc/log4j.xml':
        content => template('gerrit/log4j.xml.erb'),
        owner   => $scap_user,
        group   => $scap_user,
        mode    => '0444',
        require => File['/var/lib/gerrit2'],
    }

    if $ssh_host_key != undef {
        file { '/var/lib/gerrit2/review_site/etc/ssh_host_key':
            content   => secret("gerrit/${ssh_host_key}"),
            owner     => $scap_user,
            group     => $scap_user,
            mode      => '0440',
            require   => File['/var/lib/gerrit2'],
            show_diff => false,
        }
    }

    $ensure_replication = $replica ? {
        false   => present,
        default => absent,
    }
    file { '/var/lib/gerrit2/review_site/etc/replication.config':
        ensure  => $ensure_replication,
        content => template('gerrit/replication.config.erb'),
        owner   => $scap_user,
        group   => $scap_user,
        mode    => '0444',
        require => File['/var/lib/gerrit2'],
    }

    file { '/var/lib/gerrit2/review_site/logs':
        ensure  => 'link',
        target  => '/var/log/gerrit',
        owner   => $scap_user,
        group   => $scap_user,
        require => [File['/var/lib/gerrit2'], Scap::Target['gerrit/gerrit'], File['/var/log/gerrit']],
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
      require => [File['/var/lib/gerrit2'], Scap::Target['gerrit/gerrit']],
    }

    systemd::service { 'gerrit':
        ensure         => present,
        content        => systemd_template('gerrit'),
        service_params => {
            ensure   => 'running',
            provider => $::initsystem,
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

    nrpe::monitor_service { 'gerrit':
        ensure       => 'present',
        description  => 'gerrit process',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 --ereg-argument-array '^${java_home}/bin/java .*-jar /var/lib/gerrit2/review_site/bin/gerrit.war daemon -d /var/lib/gerrit2/review_site'",
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Gerrit',
    }
}
