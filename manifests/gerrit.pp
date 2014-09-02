# manifests/gerrit.pp
# Manifest to setup a Gerrit instance

class gerrit::instance($apache_ssl  = false,
    $slave       = false,
    $ssh_port    = '29418',
    $db_host     = '',
    $db_name     = 'reviewdb',
    $host        = '',
    $db_user     = 'gerrit',
    $ssh_key     = '',
    $ssl_cert    = 'ssl-cert-snakeoil',
    $ssl_cert_key= 'ssl-cert-snakeoil',
    $replication = '',
    $smtp_host   = '') {

    include standard,
        ldap::role::config::labs

    # Main config
    include passwords::gerrit
    $email_key = $passwords::gerrit::gerrit_email_key
    $sshport = $ssh_port
    $dbhost = $db_host
    $dbname = $db_name
    $dbuser = $db_user
    $dbpass = $passwords::gerrit::gerrit_db_pass
    $bzpass = $passwords::gerrit::gerrit_bz_pass
    $ssl_settings = ssl_ciphersuite('apache-2.2', 'compat', '7')

    # Setup LDAP
    include ldap::role::config::labs
    $ldapconfig = $ldap::role::config::labs::ldapconfig

    $ldap_hosts = $ldapconfig['servernames']
    $ldap_base_dn = $ldapconfig['basedn']
    $ldap_proxyagent = $ldapconfig['proxyagent']
    $ldap_proxyagent_pass = $ldapconfig['proxypass']

    # Configure the base URL
    $url = "https://${host}/r"

    class { 'gerrit::proxy':
        ssl_cert     => $ssl_cert,
        ssl_cert_key => $ssl_cert_key,
        host         => $host
    }

    class { 'gerrit::jetty':
        ldap_hosts           => $ldap_hosts,
        ldap_base_dn         => $ldap_base_dn,
        url                  => $url,
        dbhost               => $dbhost,
        dbname               => $dbname,
        dbuser               => $dbuser,
        hostname             => $host,
        ldap_proxyagent      => $ldap_proxyagent,
        ldap_proxyagent_pass => $ldap_proxyagent_pass,
        sshport              => $sshport,
        replication          => $replication,
        smtp_host            => $smtp_host,
        ssh_key              => $ssh_key,
    }
}

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
        source => 'puppet:///files/gerrit/gerrit',
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
        source  => 'puppet:///files/gerrit/mail/ChangeSubject.vm',
        require => Exec['install_gerrit_jetty'],
    }

    file { '/var/lib/gerrit2/review_site/etc/GerritSite.css':
        owner  => 'gerrit2',
        group  => 'gerrit2',
        mode   => '0444',
        source => 'puppet:///files/gerrit/skin/GerritSite.css',
    }

    file { '/var/lib/gerrit2/review_site/etc/GerritSiteHeader.html':
        owner  => 'gerrit2',
        group  => 'gerrit2',
        mode   => '0444',
        source => 'puppet:///files/gerrit/skin/GerritSiteHeader.html',
    }

    file { '/var/lib/gerrit2/review_site/etc/its':
        ensure  => directory,
        owner   => 'gerrit2',
        group   => 'gerrit2',
        mode    => '0755',
        require => File['/var/lib/gerrit2/review_site/etc'],
    }

    file { '/var/lib/gerrit2/review_site/etc/its/action.config':
        source  => 'puppet:///files/gerrit/its/action.config',
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
        source  => 'puppet:///files/gerrit/its/templates/DraftPublished.vm',
        owner   => 'gerrit2',
        group   => 'gerrit2',
        mode    => '0755',
        require => File['/var/lib/gerrit2/review_site/etc/its/templates'],
    }

    file { '/var/lib/gerrit2/review_site/static/page-bkg.jpg':
        owner  => 'gerrit2',
        group  => 'gerrit2',
        mode   => '0444',
        source => 'puppet:///files/gerrit/skin/page-bkg.jpg',
    }

    file { '/var/lib/gerrit2/review_site/static/wikimedia-codereview-logo.png':
        owner  => 'gerrit2',
        group  => 'gerrit2',
        mode   => '0444',
        source => 'puppet:///files/gerrit/skin/wikimedia-codereview-logo.png',
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

class gerrit::proxy($host        = '',
    $ssl_cert    = '',
    $ssl_cert_key= '') {

    apache::site { 'gerrit.wikimedia.org':
        content => template('apache/sites/gerrit.wikimedia.org.erb'),
    }

# We don't use gitweb anymore, so we're going to allow spiders again
# If it becomes a problem, just set ensure => present again
    file { '/var/www/robots.txt':
        ensure => absent,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///files/misc/robots-txt-disallow',
    }

    include ::apache::mod::rewrite

    include ::apache::mod::proxy

    include ::apache::mod::proxy_http

    include ::apache::mod::ssl

    include ::apache::mod::headers
}

class gerrit::crons {

    cron { 'list_mediawiki_extensions':
    # Gerrit is missing a public list of projects.
    # This hack list MediaWiki extensions repositories
        command => "/bin/ls -1d /var/lib/gerrit2/review_site/git/mediawiki/extensions/*.git | sed 's#.*/##' | sed 's/\\.git//' > /var/www/mediawiki-extensions.txt",
        user    => 'root',
        minute  => [0, 15, 30, 45],
    }

    cron { 'list_reviewer_counts':
    # This is useful information about the distribution of reviewers.
    # Gerrit's rest api doesn't provide an easy way to get this data.
        command => "ssh -p 29418 localhost gerrit gsql --format JSON_SINGLE -c \"'SELECT changes.change_id AS change_id, COUNT(DISTINCT patch_set_approvals.account_id) AS reviewer_count FROM changes LEFT JOIN patch_set_approvals ON (changes.change_id = patch_set_approvals.change_id) GROUP BY changes.change_id'\" > /var/www/reviewer-counts.json",
        user    => 'gerrit2',
        hour    => 1,
    }

    cron { 'clear_gerrit_logs':
    # Gerrit rotates their own logs, but doesn't clean them out
    # Delete logs older than a week
        command => "find /var/lib/gerrit2/review_site/logs/*.gz -mtime +7 -exec rm {} \\;",
        user    => 'root',
        hour    => 1
    }

    cron { 'jgit_gc':
    # Keep repo sizes sane, so people can be productive
        command => 'ssh -p 29418 localhost gerrit gc --all > /dev/null 2>&1',
        user    => 'gerrit2',
        hour    => 2,
        weekday => 6
    }
}

# Setup the `gerritslave` account on any host that wants to receive
# replication. See role::gerrit::production::replicationdest
class gerrit::replicationdest( $sshkey, $extra_groups = [], $slaveuser = 'gerritslave' ) {

    group { $slaveuser:
        ensure => present,
        name   => $slaveuser,
        system => true,
    }

    user { $slaveuser:
        name       => $slaveuser,
        groups     => $extra_groups,
        shell      => '/bin/bash',
        managehome => true,
        system     => true,
    }

    ssh_authorized_key { $slaveuser:
        ensure  => present,
        key     => $sshkey,
        type    => 'ssh-rsa',
        user    => $slaveuser,
        require => User[$slaveuser],
    }
}
