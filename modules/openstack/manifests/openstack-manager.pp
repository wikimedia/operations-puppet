# https://www.mediawiki.org/wiki/Extension:OpenStackManager
class openstack::openstack-manager(
    $openstack_version=$::openstack::version,
    $novaconfig,
    $certificate
) {
    require mediawiki::users

    if !defined(Class['webserver::php5']) {
        class {'webserver::php5': ssl => true; }
    }

    if !defined(Class['memcached']) {
        apt::pin { 'memcached':
            pin      => 'release o=Ubuntu',
            priority => '1001',
            before   => Package['memcached'],
        }
        # TODO: Remove after applied everywhere.
        file { '/etc/apt/preferences.d/memcached':
            ensure  => absent,
            require => Apt::Pin['memcached'],
            notify  => Exec['apt-get update'],
        }

        class { 'memcached':
            ip  => '127.0.0.1',
        }
    }

    $controller_hostname = $novaconfig['controller_hostname']

    if ($::lsbdistcodename == 'precise') {
        package { [ 'php5-ldap', 'php5-uuid', 'imagemagick', 'librsvg2-bin' ]:
            ensure => present;
        }
    } else {
        package { [ 'php5-ldap', 'imagemagick', 'librsvg2-bin']:
            ensure => present;
        }
    }

    $webserver_hostname = $::realm ? {
        'production' => 'wikitech.wikimedia.org',
        default      => $controller_hostname,
    }

    $webserver_hostname_aliases = $::realm ? {
        'production' => 'wmflabs.org www.wmflabs.org',
        default      => "www.${controller_hostname}",
    }

    apache::site { $webserver_hostname:
        content => template("apache/sites/${webserver_hostname}.erb"),
    }

    # ::mediawiki::scap supports syncing the wikitech wiki from tin.
    include ::mediawiki::scap

    file {
        '/a':
            ensure => directory,
            mode   => '0755',
            owner  => 'root',
            group  => 'root';
        '/var/www/robots.txt':
            ensure => present,
            mode   => '0644',
            owner  => 'root',
            group  => 'root',
            source => 'puppet:///modules/openstack/wikitech-robots.txt';
        '/a/backup':
            ensure => directory,
            mode   => '0755',
            owner  => 'root',
            group  => 'root';
        '/a/backup/public':
            ensure => directory,
            mode   => '0755',
            owner  => 'root',
            group  => 'root';
        '/usr/local/sbin/db-bak.sh':
            mode   => '0555',
            owner  => 'root',
            group  => 'root',
            source => 'puppet:///modules/openstack/db-bak.sh';
        '/usr/local/sbin/mw-files.sh':
            mode   => '0555',
            owner  => 'root',
            group  => 'root',
            source => 'puppet:///modules/openstack/mw-files.sh';
        '/usr/local/sbin/mw-xml.sh':
            mode   => '0555',
            owner  => 'root',
            group  => 'root',
            source => 'puppet:///modules/openstack/mw-xml.sh';
        '/usr/local/apache':
            ensure => directory,
            owner  => 'root',
            group  => 'root';
        '/usr/local/apache/common':
            ensure => link,
            target => '/usr/local/apache/common-local';
        '/usr/local/apache/common-local':
            ensure => link,
            target => '/srv/mediawiki';
    }

    cron {
        'run-jobs':
            ensure  => present,
            user    => $::mediawiki::users::web,
            command => '/usr/local/bin/mwscript maintenance/runJobs.php --wiki=labswiki > /dev/null 2>&1';
        'send-echo-emails':
            ensure  => present,
            user    => $::mediawiki::users::web,
            command => '/usr/local/bin/mwscript extensions/Echo/maintenance/processEchoEmailBatch.php --wiki=labswiki > /dev/null 2>&1';
        'db-bak':
            ensure  => present,
            user    => 'root',
            hour    => 1,
            minute  => 0,
            command => '/usr/local/sbin/db-bak.sh > /dev/null 2>&1',
            require => File['/a/backup'];
        'mw-xml':
            ensure  => present,
            user    => 'root',
            hour    => 1,
            minute  => 30,
            command => '/usr/local/sbin/mw-xml.sh > /dev/null 2>&1',
            require => File['/a/backup'];
        'mw-files':
            ensure  => present,
            user    => 'root',
            hour    => 2,
            minute  => 0,
            command => '/usr/local/sbin/mw-files.sh > /dev/null 2>&1',
            require => File['/a/backup'];
        'backup-cleanup':
            ensure  => present,
            user    => 'root',
            hour    => 3,
            minute  => 0,
            command => 'find /a/backup -type f -mtime +4 -delete',
            require => File['/a/backup'];
    }


    include ::apache::mod::rewrite
    include ::apache::mod::headers

    include role::backup::host
    backup::set {'a-backup': }

    include nrpe

    package { 'nova-xvpvncproxy':
        ensure => present,
    }
    package { 'nova-novncproxy':
        ensure => present,
    }
    package { 'nova-consoleauth':
        ensure => present,
    }
    package { 'novnc':
        ensure => present,
    }
}
