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

    systemd::unit { 'update-etcd-mw-config-lastindex':
        ensure  => present,
        restart => true,
        content => systemd_template('update-etcd-mw-config-lastindex'),
        require => File['/usr/local/sbin/update-etcd-mw-config-lastindex'],
    }

    systemd::unit { 'update-etcd-mw-config-lastindex.timer':
        ensure  => present,
        restart => true,
        content => systemd_template('update-etcd-mw-config-lastindex.timer'),
        require => Systemd::Unit['update-etcd-mw-config-lastindex'],
    }

    nrpe::monitor_systemd_unit_state { 'update-etcd-mw-config-lastindex':
        expected_state => 'periodic',
        lastrun        => '60',
        require        => Systemd::Unit['update-etcd-mw-config-lastindex.timer']
    }

}
