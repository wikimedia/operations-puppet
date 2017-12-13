# https://www.mediawiki.org/wiki/Extension:OpenStackManager
class openstack::wikitech::openstack_manager(
    $certificate,
    $webserver_hostname,
    $webserver_hostname_aliases,
    $wikidb,
    $wikitech_nova_ldap_proxyagent_pass,
    $wikitech_nova_ldap_user_pass,
) {

    require ::mediawiki::users
    include ::mediawiki::multimedia
    include ::apache
    include ::apache::mod::alias
    include ::apache::mod::ssl
    include ::apache::mod::php5
    # ::mediawiki::scap supports syncing the wikitech wiki from tin.
    include ::mediawiki::scap
    include ::apache::mod::rewrite
    include ::apache::mod::headers
    include ::profile::backup::host
    include ::nrpe
    include ::imagemagick::install

    class {'::openstack::wikitech::wikitechprivatesettings':
        wikitech_nova_ldap_proxyagent_pass => $wikitech_nova_ldap_proxyagent_pass,
        wikitech_nova_ldap_user_pass       => $wikitech_nova_ldap_user_pass,
    }

    package { [
        'php5-ldap',
        'librsvg2-bin']:
            ensure => 'present';
    }

    require_package([
        'python-mysqldb',
        'python-keystone']
    )

    backup::set {'a-backup': }

    if !defined(Class['memcached']) {
        apt::pin { 'memcached':
            pin      => 'release o=Ubuntu',
            priority => '1001',
            before   => Package['memcached'],
        }
        # TODO: Remove after applied everywhere.
        file { '/etc/apt/preferences.d/memcached':
            ensure  => 'absent',
            require => Apt::Pin['memcached'],
            notify  => Exec['apt-get update'],
        }

        class { '::memcached':
            ip  => '127.0.0.1',
        }
    }

    file { '/etc/apache2/sites-enabled/public-wiki-rewrites.incl':
        ensure => 'present',
        source => 'puppet:///modules/mediawiki/apache/sites/public-wiki-rewrites.incl',
        before => Service['apache2'],
    }

    $ssl_settings = ssl_ciphersuite('apache', 'compat', true)
    apache::site { $webserver_hostname:
        content => template('openstack/wikitech/wikitech.wikimedia.org.erb'),
    }

    file {
        '/a':
            ensure => 'directory',
            owner  => 'root',
            group  => 'root',
            mode   => '0755';
        '/var/www/robots.txt':
            ensure => 'present',
            owner  => 'root',
            group  => 'root',
            mode   => '0644',
            source => 'puppet:///modules/openstack/wikitech/wikitech-robots.txt';
        '/a/backup':
            ensure => 'directory',
            owner  => 'root',
            group  => 'root',
            mode   => '0755';
        '/a/backup/public':
            ensure => directory,
            mode   => '0755',
            owner  => 'root',
            group  => 'root';
        '/usr/local/sbin/db-bak.sh':
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
            source => 'puppet:///modules/openstack/wikitech/db-bak.sh';
        '/usr/local/sbin/mw-files.sh':
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
            source => 'puppet:///modules/openstack/wikitech/mw-files.sh';
        '/usr/local/sbin/mw-xml.sh':
            mode   => '0555',
            owner  => 'root',
            group  => 'root',
            source => 'puppet:///modules/openstack/wikitech/mw-xml.sh';
        '/usr/local/apache':
            ensure => 'directory',
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
        'db-bak':
            ensure  => 'present',
            user    => 'root',
            hour    => 1,
            minute  => 0,
            command => '/usr/local/sbin/db-bak.sh > /dev/null 2>&1',
            require => File['/a/backup'];
        'mw-xml':
            ensure  => 'present',
            user    => 'root',
            hour    => 1,
            minute  => 30,
            command => '/usr/local/sbin/mw-xml.sh > /dev/null 2>&1',
            require => File['/a/backup'];
        'mw-files':
            ensure  => 'present',
            user    => 'root',
            hour    => 2,
            minute  => 0,
            command => '/usr/local/sbin/mw-files.sh > /dev/null 2>&1',
            require => File['/a/backup'];
        'backup-cleanup':
            ensure  => 'present',
            user    => 'root',
            hour    => 3,
            minute  => 0,
            command => 'find /a/backup -type f -mtime +2 -delete',
            require => File['/a/backup'];
        'run-jobs':
            ensure  => 'present',
            user    => $::mediawiki::users::web,
            command => "/usr/local/bin/mwscript maintenance/runJobs.php --wiki=${wikidb} > /dev/null 2>&1";
        'update-smw':
            ensure  => 'present',
            user    => $::mediawiki::users::web,
            hour    => '*/6',
            minute  => 20,
            command => "/usr/local/bin/mwscript extensions/SemanticMediaWiki/maintenance/SMW_refreshData.php --wiki=${wikidb} > /dev/null 2>&1";
    }
}
