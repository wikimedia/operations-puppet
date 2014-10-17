class openstack::openstack-manager($openstack_version="folsom", $novaconfig, $certificate) {
    # require mediawiki::users::mwdeploy  -- temp. removed for ::mediawiki refactor -- OL

    if !defined(Class["webserver::php5"]) {
        class {'webserver::php5': ssl => true; }
    }

    if !defined(Class["memcached"]) {
        class { "memcached":
            memcached_ip => "127.0.0.1",
            pin          => true;
        }
    }

    $controller_hostname = $novaconfig["controller_hostname"]

    package { [ 'php5-ldap', 'php5-uuid', 'imagemagick', 'librsvg2-bin' ]:
        ensure => present;
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
        "/a":
            mode   => '0755',
            owner  => 'root',
            group  => 'root',
            ensure => directory;
        "/var/www/robots.txt":
            ensure => present,
            mode   => '0644',
            owner  => 'root',
            group  => 'root',
            source => "puppet:///modules/openstack/wikitech-robots.txt";
        "/a/backup":
            mode   => '0755',
            owner  => 'root',
            group  => 'root',
            ensure => directory;
        "/a/backup/public":
            mode   => '0755',
            owner  => 'root',
            group  => 'root',
            ensure => directory;
        "/usr/local/sbin/db-bak.sh":
            mode   => '0555',
            owner  => 'root',
            group  => 'root',
            source => "puppet:///modules/openstack/db-bak.sh";
        "/usr/local/sbin/mw-files.sh":
            mode   => '0555',
            owner  => 'root',
            group  => 'root',
            source => "puppet:///modules/openstack/mw-files.sh";
        "/usr/local/sbin/mw-xml.sh":
            mode   => '0555',
            owner  => 'root',
            group  => 'root',
            source => "puppet:///modules/openstack/mw-xml.sh";
    }

    cron {
        "run-jobs":
            user    => 'apache',
            command => '/usr/local/bin/mwscript maintenance/runJobs.php --wiki=labswiki > /dev/null 2>&1',
            ensure  => present;
        "send-echo-emails":
            user    => 'apache',
            command => '/usr/local/bin/mwscript extensions/Echo/maintenance/processEchoEmailBatch.php --wiki=labswiki > /dev/null 2>&1',
            ensure  => present;
        "db-bak":
            user    => 'root',
            hour    => 1,
            minute  => 0,
            command => '/usr/local/sbin/db-bak.sh > /dev/null 2>&1',
            require => File["/a/backup"],
            ensure  => present;
        "mw-xml":
            user    => 'root',
            hour    => 1,
            minute  => 30,
            command => '/usr/local/sbin/mw-xml.sh > /dev/null 2>&1',
            require => File["/a/backup"],
            ensure  => present;
        "mw-files":
            user    => 'root',
            hour    => 2,
            minute  => 0,
            command => '/usr/local/sbin/mw-files.sh > /dev/null 2>&1',
            require => File["/a/backup"],
            ensure  => present;
        "backup-cleanup":
            user    => 'root',
            hour    => 3,
            minute  => 0,
            command => 'find /a/backup -type f -mtime +4 -delete',
            require => File["/a/backup"],
            ensure  => present;
    }


    include ::apache::mod::rewrite
    include ::apache::mod::headers

    include backup::host
    backup::set {'a-backup': }

    include nrpe

    if ( $openstack_version == 'havana' ) {
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
}
