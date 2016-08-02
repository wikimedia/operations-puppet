class gerrit::jetty(
    $db_host,
    $replication = '',
    $url = "https://${::gerrit::host}/r",
    $db_name = 'reviewdb',
    $db_user = 'gerrit',
    $git_dir = 'git',
    $ssh_host_key = undef,
    $heap_limit = '28g',
    ) {

    include nrpe

    # Private config
    include passwords::gerrit
    $email_key = $passwords::gerrit::gerrit_email_key
    $db_pass = $passwords::gerrit::gerrit_db_pass
    $phab_cert = $passwords::gerrit::gerrit_phab_cert

    # Setup LDAP
    include ldap::role::config::labs
    $ldapconfig = $ldap::role::config::labs::ldapconfig

    $ldap_hosts = $ldapconfig['servernames']
    $ldap_base_dn = $ldapconfig['basedn']
    $ldap_proxyagent = $ldapconfig['proxyagent']
    $ldap_proxyagent_pass = $ldapconfig['proxypass']

    require_package('openjdk-7-jdk')

    package { 'gerrit':
        ensure => present,
    }

    file { '/var/lib/gerrit2/':
        ensure  => directory,
        mode    => '0755',
        owner   => 'gerrit2',
        require => Package['gerrit'],
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
        owner   => 'gerrit2',
        group   => 'gerrit2',
        mode    => '0600',
        require => File['/var/lib/gerrit2/.ssh'],
        content => secret('gerrit/id_rsa'),
    }

    file { '/var/lib/gerrit2/review_site':
        ensure  => directory,
        owner   => 'gerrit2',
        group   => 'gerrit2',
        mode    => '0644',
        require => [File['/var/lib/gerrit2'],Package['gerrit']],
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
        content => template('gerrit/gerrit.config.erb'),
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

    if $ssh_host_key != undef {
        file { '/var/lib/gerrit2/review_site/etc/ssh_host_key':
            content => secret("gerrit/${ssh_host_key}"),
            owner   => 'gerrit2',
            group   => 'gerrit2',
            mode    => '0440',
            require => File['/var/lib/gerrit2/review_site/etc'],
        }
    }

    file { '/var/lib/gerrit2/review_site/etc/replication.config':
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

    exec { 'install_gerrit_jetty':
        creates => '/var/lib/gerrit2/review_site/bin',
        user    => 'gerrit2',
        group   => 'gerrit2',
        cwd     => '/var/lib/gerrit2',
        command => '/usr/bin/java -jar gerrit.war init -d review_site --batch --no-auto-start',
        require => [
            File['/var/lib/gerrit2/review_site/etc/gerrit.config'],
            File['/var/lib/gerrit2/review_site/etc/secure.config'],
        ],
    }

    exec { 'reindex_gerrit_jetty':
        creates => '/var/lib/gerrit2/review_site/index',
        user    => 'gerrit2',
        group   => 'gerrit2',
        cwd     => '/var/lib/gerrit2',
        command => '/usr/bin/java -jar gerrit.war reindex -d review_site --threads 4',
        require => Exec['install_gerrit_jetty'],
    }

    service { 'gerrit':
        ensure    => running,
        subscribe => [File['/var/lib/gerrit2/review_site/etc/gerrit.config'],
                    File['/var/lib/gerrit2/review_site/etc/secure.config']],
        enable    => true,
        hasstatus => false,
        status    => '/etc/init.d/gerrit check',
        require   => Exec['reindex_gerrit_jetty'],
    }

    nrpe::monitor_service { 'gerrit':
        description  => 'gerrit process',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 --ereg-argument-array '^GerritCodeReview .*-jar /var/lib/gerrit2/review_site/bin/gerrit.war'"
    }
}
