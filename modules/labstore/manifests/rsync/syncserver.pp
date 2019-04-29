class labstore::rsync::syncserver(
    Array[Stdlib::Host] $hosts_allow = [],
    Stdlib::Unixpath $datapath = '/exp',
    Integer $interval=600,
    String $user='nobody',
    String $group='nogroup',
    String $rsync_opts='',
    Stdlib::Host $primary_host=undef,
    String $niceness = '+10',
    Boolean $is_active = false,
)  {
    include labstore::backup_keys

    file { '/usr/local/sbin/syncserver':
        ensure => 'present',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/labstore/syncserver.py',
    }

    $ensure = $is_active? {
        true    => 'present',
        default => 'absent',
    }
    systemd::service { 'syncserver':
        ensure    => $ensure,
        content   => systemd_template('syncserver'),
        subscribe => File['/usr/local/sbin/syncserver'],
    }
}
