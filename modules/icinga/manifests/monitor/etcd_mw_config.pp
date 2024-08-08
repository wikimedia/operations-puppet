# == Class: icinga::monitor::mw_etcd_config
#
# Monitor the last modified intex in Etcd for MediaWiki config
#
class icinga::monitor::etcd_mw_config (
    String $icinga_user,
){
    file { '/usr/local/bin/update-etcd-mw-config-lastindex':
        ensure => absent,
    }

    systemd::timer::job { 'update-etcd-mw-config-lastindex':
        ensure             => absent,
    }
}
