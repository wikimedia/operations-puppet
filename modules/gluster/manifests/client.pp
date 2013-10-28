# gluster::client
#
#  Installs gluster client packages, sets up logging.
#
#  We also do some logrotate magic to work around a bug in gluster's
#  native log-rotate.
#
class gluster::client {
    package { 'glusterfs-client':
        ensure => present;
    }

    file { [ '/var/log/glusterfs', '/var/log/glusterfs/bricks' ]:
        ensure => directory,
        before => File['/etc/logrotate.d/glusterlogs'],
    }

    file { '/etc/logrotate.d/glusterlogs':
        ensure => present,
        mode   => '0664',
        source => 'puppet:///modules/gluster/glusterlogs',
        group  => 'root',
        owner  => 'root',
    }

    # Gluster installs this but it doesn't work and breaks
    # the behavior of /etc/logrotate.d/glusterlogs.
    file { '/etc/logrotate.d/glusterfs-common':
        ensure => absent,
    }
}
