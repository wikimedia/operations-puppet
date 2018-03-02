# https://www.mediawiki.org/wiki/Extension:OpenStackManager
class openstack::wikitech::wikitech_static_sync {

    file {
        '/a':
            ensure => 'directory',
            owner  => 'root',
            group  => 'root',
            mode   => '0755';
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
    }

    cron {
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
    }
}
