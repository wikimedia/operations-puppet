class gerrit::jetty(
    $db_host,
    $replication,
    $url = "https://${::gerrit::host}/r",
    $db_name = 'reviewdb',
    $db_user = 'gerrit',
    $git_dir = 'git',
    $gid     = 444,
    $uid     = 444,
    $ssh_host_key = undef,
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

    require_package('openjdk-7-jre')

    package { 'gerrit':
        ensure => present,
    }

    group { 'gerrit2':
        ensure => present,
        gid    => $gid,
        system => true,
    }

    user { 'gerrit2':
        ensure  => present,
        home    => '/var/lib/gerrit2',
        system  => true,
        gid     => $gid,
        uid     => $uid,
        require => Group['gerrit2'],
    }

    file { '/var/lib/gerrit2/':
        ensure  => directory,
        mode    => '0755',
        owner   => 'gerrit2',
        require => [Package['gerrit'], User['gerrit2']],
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

    file { '/var/lib/gerrit2/review_site/lib':
        ensure  => directory,
        owner   => 'gerrit2',
        group   => 'gerrit2',
        mode    => '0444',
        require => [Exec['install_gerrit_jetty'],
                    File['/var/lib/gerrit2/review_site']
        ],
    }

    # This file is tuned for gerrit-2.8.1-4-ga1048ce. If you update gerrit,
    # you also need to update this jar to match the BouncyCastle version
    # required by the fresh gerrit.
    file { '/var/lib/gerrit2/review_site/lib/bcprov-jdk16-144.jar':
        ensure  => link,
        owner   => 'gerrit2',
        group   => 'gerrit2',
        mode    => '0444',
        target  => '/var/lib/gerrit2/review_site/plugins/bouncycastle/bcprov-1.44-from-Debian-wheezy.jar',
        require => [File['/var/lib/gerrit2/review_site/lib']
        ],
    }

    exec { 'install_gerrit_jetty':
        creates => '/var/lib/gerrit2/review_site/bin',
        user    => 'gerrit2',
        group   => 'gerrit2',
        cwd     => '/var/lib/gerrit2',
        command => '/usr/bin/java -jar gerrit.war init -d review_site --batch --no-auto-start',
        require => [Package['gerrit'],
                    File['/var/lib/gerrit2/review_site/etc/gerrit.config'],
                    File['/var/lib/gerrit2/review_site/etc/secure.config']
        ],
    }

    service { 'gerrit':
        ensure    => running,
        subscribe => [File['/var/lib/gerrit2/review_site/etc/gerrit.config'],
                    File['/var/lib/gerrit2/review_site/etc/secure.config']],
        enable    => true,
        hasstatus => false,
        status    => '/etc/init.d/gerrit check',
        require   => [Exec['install_gerrit_jetty'],
                      File['/var/lib/gerrit2/review_site/lib/bcprov-jdk16-144.jar']
        ],
    }

    nrpe::monitor_service { 'gerrit':
        description  => 'gerrit process',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 --ereg-argument-array '^GerritCodeReview .*-jar /var/lib/gerrit2/review_site/bin/gerrit.war'"
    }
}
