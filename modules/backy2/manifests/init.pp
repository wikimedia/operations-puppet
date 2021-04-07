# Class backy2
#
# Install backy2 and configure for backing up ceph rbd volumes to local storage
#
# This class expects to find a ceph config in /etc/ceph/ceph.conf, which
#  is typically provided by profile::ceph::client::rbd
#
# On an initial install, the database can be created with
#
# $ sudo backy2 initdb
#
# Parameters:
#
#  cluster_name: ceph cluster name
#  rados_name: ceph client username
#
# Requires:
#
# Sample Usage
#   include backy2
class backy2(
    String       $cluster_name,
    String       $rados_name = 'client.admin',
    ) {

    # The upstream backy2 deb is available from
    #    https://github.com/wamdam/backy2/releases
    #
    # It targets ubuntu but installs just fine on Debian Buster.
    #
    # The dependencies are a bit incomplete, so rather than take any
    #  chances I'm enumerating them here.
    $packages = [
        'python3-alembic',
        'python3-dateutil',
        'python3-fusepy',
        'python3-mysqldb',
        'python3-prettytable',
        'python3-rados',
        'python3-rbd',
        'python3-setproctitle',
        'python3-shortuuid',
        'python3-sqlalchemy',
        'python3-lz4',
        'python3-crypto',
        'python3-pycryptodome',
    ]
    ensure_packages($packages)
    ensure_packages('backy2')
    $packages.each |String $package| {
      Package[$package] -> Package['backy2']
    }

    file {
        '/srv/backy2':
            ensure => 'directory';
        '/srv/backy2/data':
            ensure  => 'directory',
            require => File['/srv/backy2'];
        '/etc/backy.cfg':
            content   => template('backy2/backy.cfg.erb'),
            owner     => 'root',
            group     => 'root',
            mode      => '0440',
            show_diff => false,
            require   => Package['backy2'];
    }

    # Hack in a one-character fix to an upstream bug.  There is a pending
    #  pull request for this, here: https://github.com/wamdam/backy2/pull/72
    file { '/usr/lib/python3/dist-packages/backy2/meta_backends/sql.py':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/backy2/sql.py',
        require => Package['backy2'];
    }


}
