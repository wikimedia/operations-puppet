class ceph::rook(
) {
    file { '/etc/rook/':
        ensure => 'directory',
    }
    file { '/etc/rook/common.yaml':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0400',
        source => 'puppet:///modules/ceph/rook/common.yaml',
    }
    file { '/etc/rook/operator.yaml':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0400',
        source => 'puppet:///modules/ceph/rook/operator.yaml',
    }
    file { '/etc/rook/cluster.yaml':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0400',
        source => 'puppet:///modules/ceph/rook/cluster.yaml',
    }
    file { '/etc/rook/toolbox.yaml':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0400',
        source => 'puppet:///modules/ceph/rook/toolbox.yaml',
    }
}
