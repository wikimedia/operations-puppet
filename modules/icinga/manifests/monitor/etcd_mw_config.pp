# == Class: icinga::monitor::mw_etcd_config
#
# Monitor the last modified intex in Etcd for MediaWiki config
#
class icinga::monitor::etcd_mw_config {
    file { '/usr/local/sbin/update-etcd-mw-config-lastindex':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0640',
        source => template('icinga/update-etcd-mw-config-lastindex.erb'),
    }

    systemd::unit { 'update-etcd-mw-config-lastindex':
        ensure  => present,
        restart => true,
        content => systemd_template('update-etcd-mw-config-lastindex')
        require => File['/usr/local/sbin/update-etcd-mw-config-lastindex']
    }
}
