class labstore::rsync::syncserver(
    Array[Stdlib::Host] $hosts_allow = [],
    Stdlib::Unixpath $datapath = '',
    Integer $interval=600,
    String $user='',
    String $group='',
    String $rsync_opts='',
    Stdlib::Host $primary_host=undef,
    String $niceness = '+10',
)  {
    include labstore::rsync::common

    file { '/etc/rsyncd.d/10-rsync-datasets_to_peers.conf':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('labstore/rsync/rsyncd.conf.datasets_to_peers.erb'),
        notify  => Exec['update-rsyncd.conf'],
    }

    file { '/usr/local/sbin/syncserver':
        ensure => 'present',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/labstore/syncserver.py',
    }

    systemd::service { 'syncserver':
        ensure    => 'present',
        restart   => true,
        content   => systemd_template('syncserver'),
        subscribe => File['/usr/local/sbin/syncserver'],
    }
}
