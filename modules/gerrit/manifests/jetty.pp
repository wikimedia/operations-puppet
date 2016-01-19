class gerrit::jetty ($ldap_hosts,
    $ldap_base_dn,
    $url,
    $dbhost,
    $dbname,
    $dbuser,
    $hostname,
    $sshport,
    $ldap_proxyagent,
    $ldap_proxyagent_pass,
    $replication,
    $smtp_host,
    $ssh_key) {

    include gerrit::crons
    include nrpe

    package { 'openjdk-7-jre':
        ensure => latest,
    }

    package { 'python-paramiko':
        ensure => latest,
    }

    package { 'gerrit':
        ensure => present,
    }

    # TODO: Make this go away -- need to stop using gerrit2 for hook actions
    ssh::userkey { 'gerrit2':
        ensure  => present,
        content => $ssh_key,
        require => Package['gerrit'],
    }

    file { '/etc/default/gerritcodereview':
        source => 'puppet:///modules/gerrit/gerrit',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    file { '/var/lib/gerrit2/':
        ensure  => directory,
        mode    => '0755',
        owner   => 'gerrit2',
        require => Package['gerrit'],
    }

    file { '/var/lib/gerrit2/.ssh':
        ensure  => directory,
        mode    => '0600',
        owner   => 'gerrit2',
        require => File['/var/lib/gerrit2'],
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
        mode    => '0755',
        require => [File['/var/lib/gerrit2'],
                    Package['gerrit']],
    }

    file { '/var/lib/gerrit2/review_site/etc':
        ensure  => directory,
        owner   => 'gerrit2',
        group   => 'gerrit2',
        mode    => '0755',
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
        mode    => '0444',
        require => File['/var/lib/gerrit2/review_site/etc'],
    }

    file { '/var/lib/gerrit2/review_site/etc/replication.config':
        content => template('gerrit/replication.config.erb'),
        owner   => 'gerrit2',
        group   => 'gerrit2',
        mode    => '0444',
        require => File['/var/lib/gerrit2/review_site/etc'],
    }

    file { '/var/lib/gerrit2/review_site/etc/mail/ChangeSubject.vm':
        owner   => 'gerrit2',
        group   => 'gerrit2',
        mode    => '0444',
        source  => 'puppet:///modules/gerrit/mail/ChangeSubject.vm',
        require => Exec['install_gerrit_jetty'],
    }

    file { '/var/lib/gerrit2/review_site/etc/GerritSite.css':
        owner  => 'gerrit2',
        group  => 'gerrit2',
        mode   => '0444',
        source => 'puppet:///modules/gerrit/skin/GerritSite.css',
    }

    file { '/var/lib/gerrit2/review_site/etc/GerritSiteHeader.html':
        owner  => 'gerrit2',
        group  => 'gerrit2',
        mode   => '0444',
        source => 'puppet:///modules/gerrit/skin/GerritSiteHeader.html',
    }

    file { '/var/lib/gerrit2/review_site/etc/its':
        ensure  => directory,
        owner   => 'gerrit2',
        group   => 'gerrit2',
        mode    => '0755',
        require => File['/var/lib/gerrit2/review_site/etc'],
    }

    file { '/var/lib/gerrit2/review_site/etc/its/action.config':
        source  => 'puppet:///modules/gerrit/its/action.config',
        owner   => 'gerrit2',
        group   => 'gerrit2',
        mode    => '0755',
        require => File['/var/lib/gerrit2/review_site/etc/its'],
    }

    file { '/var/lib/gerrit2/review_site/etc/its/templates':
        ensure  => directory,
        owner   => 'gerrit2',
        group   => 'gerrit2',
        mode    => '0755',
        require => File['/var/lib/gerrit2/review_site/etc/its'],
    }

    file { '/var/lib/gerrit2/review_site/etc/its/templates/DraftPublished.vm':
        source  => 'puppet:///modules/gerrit/its/templates/DraftPublished.vm',
        owner   => 'gerrit2',
        group   => 'gerrit2',
        mode    => '0755',
        require => File['/var/lib/gerrit2/review_site/etc/its/templates'],
    }

    file { '/var/lib/gerrit2/review_site/etc/its/templates/PatchSetCreated.vm':
        source  => 'puppet:///modules/gerrit/its/templates/PatchSetCreated.vm',
        owner   => 'gerrit2',
        group   => 'gerrit2',
        mode    => '0755',
        require => File['/var/lib/gerrit2/review_site/etc/its/templates'],
    }

    file { '/var/lib/gerrit2/review_site/etc/its/templates/DraftPublishedPhabricator.vm':
        ensure  => absent,
    }

    file { '/var/lib/gerrit2/review_site/etc/its/templates/PatchSetCreatedPhabricator.vm':
        ensure  => absent,
    }

    file { '/var/lib/gerrit2/review_site/static/page-bkg.cache.jpg':
        owner  => 'gerrit2',
        group  => 'gerrit2',
        mode   => '0444',
        source => 'puppet:///modules/gerrit/skin/page-bkg.cache.jpg',
    }

    file { '/var/lib/gerrit2/review_site/static/wikimedia-codereview-logo.cache.png':
        owner  => 'gerrit2',
        group  => 'gerrit2',
        mode   => '0444',
        source => 'puppet:///modules/gerrit/skin/wikimedia-codereview-logo.cache.png',
    }

    file { '/var/lib/gerrit2/review_site/hooks':
        ensure  => directory,
        owner   => 'gerrit2',
        group   => 'gerrit2',
        mode    => '0755',
        require => Exec['install_gerrit_jetty'],
    }

    file { '/var/lib/gerrit2/review_site/lib':
        ensure  => directory,
        owner   => 'gerrit2',
        group   => 'gerrit2',
        mode    => '0755',
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
