# == Class: icinga::monitor::mw_etcd_config
#
# Monitor the last modified intex in Etcd for MediaWiki config
#
class icinga::monitor::etcd_mw_config (
    String $icinga_user,
){
    file { '/usr/local/bin/update-etcd-mw-config-lastindex':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/icinga/update-etcd-mw-config-lastindex',
    }

    systemd::timer::job { 'update-etcd-mw-config-lastindex':
        ensure             => present,
        user               => $icinga_user,
        description        => 'Update the etcd last modified index for MediaWiki config',
        command            => '/usr/local/bin/update-etcd-mw-config-lastindex',
        interval           => {'start' => 'OnUnitInactiveSec', 'interval' => '30s'},
        monitoring_enabled => true,
    }
}
