# https://www.mediawiki.org/wiki/Extension:OpenStackManager
class openstack::wikitech::wikitech_static_sync {

    file {
        '/srv/backup':
            ensure => 'directory',
            owner  => 'root',
            group  => 'root',
            mode   => '0755';
        '/srv/backup/public':
            ensure => directory,
            mode   => '0755',
            owner  => 'root',
            group  => 'root';
        '/usr/local/sbin/mw-xml.sh':
            mode   => '0555',
            owner  => 'root',
            group  => 'root',
            source => 'puppet:///modules/openstack/wikitech/mw-xml.sh';
    }

    $minute = fqdn_rand(60)

    systemd::timer::job { 'mw-xml':
        ensure => absent,
    }
}
