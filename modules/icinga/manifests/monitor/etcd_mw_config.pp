# == Class: icinga::monitor::mw_etcd_config
#
# Monitor the last modified intex in Etcd for MediaWiki config
#
class icinga::monitor::etcd_mw_config {
    file { '/usr/local/bin/update-etcd-mw-config-lastindex':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/icinga/update-etcd-mw-config-lastindex',
    }

    systemd::service { 'update-etcd-mw-config-lastindex':
        ensure  => present,
        restart => true,
        content => systemd_template('update-etcd-mw-config-lastindex'),
    }

    systemd::service { 'update-etcd-mw-config-lastindex.timer':
        ensure         => present,
        restart        => true,
        service_params => { 'provider' => 'systemd' },
        content        => systemd_template('update-etcd-mw-config-lastindex.timer'),
    }

    nrpe::monitor_systemd_unit_state { 'update-etcd-mw-config-lastindex':
        expected_state => 'periodic',
        lastrun        => '60',
    }

}
