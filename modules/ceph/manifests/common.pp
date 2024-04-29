# Class: ceph::common
#
# This class configures the host for the ceph-common package.
#
# Parameters
#    - $home_dir
#        The ceph user home directory (usually the top level data directory)
#
#   - $ceph_repository_component
#        The repository component to use to pull the ceph packages from
#
class ceph::common (
    Stdlib::Unixpath $home_dir,
    String           $ceph_repository_component,
) {
    # The ceph-common package is the preferred mechanism to create the initial
    # ceph user and group, since this will set pre-allocated static uid/gid values of 64045.
    # See: https://salsa.debian.org/debian/base-passwd/-/blob/master/README?ref_type=heads&plain=1#L50
    # By ensuring that the ceph group depends on ceph-common we will allow new server reimages to use
    # the static uid/gid without changing the uid on existing ceph deployments.
    group { 'ceph':
        ensure  => present,
        system  => true,
        require => Package['ceph-common'],
    }

    user { 'ceph':
        ensure     => present,
        gid        => 'ceph',
        shell      => '/usr/sbin/nologin',
        comment    => 'Ceph storage service',
        home       => $home_dir,
        managehome => false,
        system     => true,
        require    => Group['ceph'],
    }

    # Ceph common package used for all services and clients
    ensure_packages([
      'ceph-common',
      # fio is used for performance tests and debugging
      'fio',
    ])

    file { '/var/lib/ceph':
        ensure  => directory,
        mode    => '0750',
        owner   => 'ceph',
        group   => 'ceph',
        require => User['ceph'],
    }

    file { '/var/lib/ceph/bootstrap-osd':
        ensure  => directory,
        mode    => '0750',
        owner   => 'ceph',
        group   => 'ceph',
        require => User['ceph'],
    }

    file { '/var/log/ceph':
        ensure  => directory,
        mode    => '0755',
        owner   => 'ceph',
        group   => 'ceph',
        require => User['ceph'],
    }

    file { '/var/run/ceph':
        ensure  => directory,
        mode    => '0750',
        owner   => 'ceph',
        group   => 'ceph',
        require => User['ceph'],
    }

    # Make sure that the ceph component is preferred to any other backports repository
    apt::package_from_component { 'ceph':
        ensure_packages => false,
        priority        => 1003,
        packages        => ['*'],
        component       => $ceph_repository_component,
        before          => Package['ceph-common'],
    }
}
