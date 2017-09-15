# sets up jetty for gerrit
# https://projects.eclipse.org/projects/rt.jetty/developer
class gerrit::jetty(
    $db_host = 'localhost',
    $replication = '',
    $url = "https://${::gerrit::host}/r",
    $db_name = 'reviewdb',
    $db_user = 'gerrit',
    $git_dir = 'git',
    $ssh_host_key = undef,
    $heap_limit = '20g',
    $slave = false,
    $java_home = '/usr/lib/jvm/java-8-openjdk-amd64/jre',
    $log_host = undef,
    $log_port = '4560',
    $config = 'gerrit.config.erb',
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

    include ::nrpe

    # Private config
    include ::passwords::gerrit
    $email_key = $passwords::gerrit::gerrit_email_key
    $db_pass = $passwords::gerrit::gerrit_db_pass
    $phab_cert = $passwords::gerrit::gerrit_phab_cert

    # Setup LDAP
    include ::ldap::role::config::labs
    $ldapconfig = $ldap::role::config::labs::ldapconfig

    $ldap_hosts = $ldapconfig['servernames']
    $ldap_base_dn = $ldapconfig['basedn']
    $ldap_proxyagent = $ldapconfig['proxyagent']
    $ldap_proxyagent_pass = $ldapconfig['proxypass']

    $java_options = [
        '-Xloggc:/srv/gerrit/jvmlogs/jvm_gc.%p.log',
        '-XX:+PrintGCApplicationStoppedTime',
        '-XX:+PrintGCDetails',
        '-XX:+PrintGCDateStamps',
        '-XX:+PrintTenuringDistribution',
        '-XX:+PrintGCCause',
        '-XX:+UseGCLogFileRotation',
        '-XX:NumberOfGCLogFiles=10',
        '-XX:GCLogFileSize=2M',
        # '-Dlog4j.configuration=file:///var/lib/gerrit2/review_site/etc/log4j.properties',
    ]

    require_package([
        'openjdk-8-jdk',
        'gerrit',
        'libbcprov-java',
        'libbcpkix-java',
        'libmysql-java',
    ])

    scap::target { 'gerrit/gerrit':
        deploy_user => 'gerrit2',
        manage_user => false,
        key_name    => 'gerrit',
    }

    file { '/srv/gerrit':
        ensure => directory,
        owner  => 'gerrit2',
        group  => 'gerrit2',
        mode   => '0664',
    }

    file { '/srv/gerrit/jvmlogs':
        ensure  => directory,
        owner   => 'gerrit2',
        group   => 'gerrit2',
        mode    => '0664',
        require => File['/srv/gerrit'],
    }

    file { '/srv/gerrit/git':
        ensure  => directory,
        owner   => 'gerrit2',
        group   => 'gerrit2',
        mode    => '0775',
        require => File['/srv/gerrit'],
    }

    file { '/var/lib/gerrit2/':
        ensure  => directory,
        mode    => '0755',
        owner   => 'gerrit2',
        require => Package['gerrit'],
    }

    file { '/var/lib/gerrit2/gerrit.war':
      ensure  => 'link',
      target  => '/srv/deployment/gerrit/gerrit/gerrit.war',
      require => [File['/var/lib/gerrit2'], Scap::Target['gerrit/gerrit']],
    }

    file { '/var/lib/gerrit2/.gitconfig':
        ensure  => directory,
        mode    => '0644',
        owner   => 'gerrit2',
        group   => 'gerrit2',
        require => File['/var/lib/gerrit2'],
        source  => 'puppet:///modules/gerrit/.gitconfig',
    }

    file { '/var/lib/gerrit2/.ssh':
        ensure  => directory,
        recurse => remote,
        mode    => '0644',
        owner   => 'gerrit2',
        group   => 'gerrit2',
        require => File['/var/lib/gerrit2'],
        source  => 'puppet:///modules/gerrit/.ssh',
    }

    file { '/var/lib/gerrit2/.ssh/id_rsa':
        owner     => 'gerrit2',
        group     => 'gerrit2',
        mode      => '0400',
        require   => File['/var/lib/gerrit2/.ssh'],
        content   => secret('gerrit/id_rsa'),
        show_diff => false,
    }

    ssh::userkey { 'gerrit2-scap':
        ensure  => present,
        user    => 'gerrit2',
        skey    => 'gerrit-scap',
        content => secret('keyholder/gerrit.pub'),
    }

    ssh::userkey { 'gerrit2-cluster-sync':
        ensure => present,
        user   => 'gerrit2',
        source => 'puppet:///modules/gerrit/id_rsa.pub'
    }

    file { '/var/lib/gerrit2/review_site':
        ensure  => directory,
        owner   => 'gerrit2',
        group   => 'gerrit2',
        mode    => '0644',
        require => [File['/var/lib/gerrit2'],Package['gerrit']],
    }

    file { '/var/lib/gerrit2/review_site/lib':
        ensure  => directory,
        owner   => 'gerrit2',
        group   => 'gerrit2',
        mode    => '0555',
        require => [File['/var/lib/gerrit2/review_site'],Package['gerrit']],
    }

    file { '/var/lib/gerrit2/review_site/lib/bcprov-1.49.jar':
        ensure  => 'link',
        target  => '/usr/share/java/bcprov-1.49.jar',
        require => [File['/var/lib/gerrit2/review_site/lib'], Package['libbcprov-java']],
    }

    file { '/var/lib/gerrit2/review_site/lib/bcpkix-1.49.jar':
        ensure  => 'link',
        target  => '/usr/share/java/bcpkix-1.49.jar',
        require => [File['/var/lib/gerrit2/review_site/lib'], Package['libbcpkix-java']],
    }

    file { '/var/lib/gerrit2/review_site/lib/mysql-connector-java.jar':
        ensure  => 'link',
        target  => '/usr/share/java/mysql-connector-java.jar',
        require => [File['/var/lib/gerrit2/review_site/lib'], Package['libmysql-java']],
    }

    file { '/var/lib/gerrit2/review_site/etc':
        ensure  => directory,
        recurse => remote,
        owner   => 'gerrit2',
        group   => 'gerrit2',
        mode    => '0444',
        source  => 'puppet:///modules/gerrit/etc',
        require => File['/var/lib/gerrit2/review_site'],
    }

    file { '/var/lib/gerrit2/review_site/etc/gerrit.config':
        content => template("gerrit/${config}"),
        owner   => 'gerrit2',
        group   => 'gerrit2',
        mode    => '0444',
        require => File['/var/lib/gerrit2/review_site/etc'],
    }

    file { '/var/lib/gerrit2/review_site/etc/secure.config':
        content => template('gerrit/secure.config.erb'),
        owner   => 'gerrit2',
        group   => 'gerrit2',
        mode    => '0440',
        require => File['/var/lib/gerrit2/review_site/etc'],
    }

    file { '/var/lib/gerrit2/review_site/etc/log4j.properties':
        content => template('gerrit/log4j.properties.erb'),
        owner   => 'gerrit2',
        group   => 'gerrit2',
        mode    => '0444',
        require => File['/var/lib/gerrit2/review_site/etc'],
    }

    if $ssh_host_key != undef {
        file { '/var/lib/gerrit2/review_site/etc/ssh_host_key':
            content   => secret("gerrit/${ssh_host_key}"),
            owner     => 'gerrit2',
            group     => 'gerrit2',
            mode      => '0440',
            require   => File['/var/lib/gerrit2/review_site/etc'],
            show_diff => false,
        }
    }

    $ensure_replication = $slave ? {
        false   => present,
        default => absent,
    }
    file { '/var/lib/gerrit2/review_site/etc/replication.config':
        ensure  => $ensure_replication,
        content => template('gerrit/replication.config.erb'),
        owner   => 'gerrit2',
        group   => 'gerrit2',
        mode    => '0444',
        require => File['/var/lib/gerrit2/review_site/etc'],
    }

    file { '/var/lib/gerrit2/review_site/static':
        ensure  => directory,
        recurse => remote,
        owner   => 'gerrit2',
        group   => 'gerrit2',
        mode    => '0444',
        source  => 'puppet:///modules/gerrit/static',
    }

    file { '/var/lib/gerrit2/review_site/plugins':
      ensure  => 'link',
      target  => '/srv/deployment/gerrit/gerrit/plugins',
      require => [File['/var/lib/gerrit2/review_site'], Scap::Target['gerrit/gerrit']],
    }

    service { 'gerrit':
        ensure    => running,
        enable    => true,
        hasstatus => false,
        status    => '/etc/init.d/gerrit check',
    }

    file { '/etc/default/gerritcodereview':
        ensure => 'link',
        target => '/etc/default/gerrit',
    }

    nrpe::monitor_service { 'gerrit':
        description  => 'gerrit process',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 --ereg-argument-array '^GerritCodeReview .*-jar /var/lib/gerrit2/review_site/bin/gerrit.war'",
    }

    cron { 'clear_gerrit_logs':
    # Gerrit rotates their own logs, but doesn't clean them out
    # Delete logs older than a week
        command => 'find /var/lib/gerrit2/review_site/logs/ -name "*.gz" -mtime +7 -delete',
        user    => 'root',
        hour    => 1,
    }
}
