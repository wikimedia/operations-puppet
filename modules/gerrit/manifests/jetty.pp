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
    ssh_authorized_key { $name:
        ensure  => present,
        key     => $ssh_key,
        type    => 'ssh-rsa',
        user    => 'gerrit2',
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
        source  => 'puppet:///private/gerrit/id_rsa',
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

    file { '/var/lib/gerrit2/review_site/static/page-bkg.jpg':
        owner  => 'gerrit2',
        group  => 'gerrit2',
        mode   => '0444',
        source => 'puppet:///modules/gerrit/skin/page-bkg.jpg',
    }

    file { '/var/lib/gerrit2/review_site/static/wikimedia-codereview-logo.png':
        owner  => 'gerrit2',
        group  => 'gerrit2',
        mode   => '0444',
        source => 'puppet:///modules/gerrit/skin/wikimedia-codereview-logo.png',
    }

    file { '/var/lib/gerrit2/review_site/hooks':
        ensure  => directory,
        owner   => 'gerrit2',
        group   => 'gerrit2',
        mode    => '0755',
        require => Exec['install_gerrit_jetty'],
    }

    git::clone { 'operations/gerrit/plugins':
        directory => '/var/lib/gerrit2/review_site/plugins',
        branch    => 'master',
        origin    => 'https://gerrit.wikimedia.org/r/p/operations/gerrit/plugins.git',
        owner     => 'gerrit2',
        group     => 'gerrit2',
        require   => File['/var/lib/gerrit2/review_site'],
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
        require   => Exec['install_gerrit_jetty'],
    }

    nrpe::monitor_service { 'gerrit':
        description  => 'gerrit process',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 --ereg-argument-array '^GerritCodeReview .*-jar /var/lib/gerrit2/review_site/bin/gerrit.war'"
    }
}
