# = Class: libraryupgrader
#
# This class sets up libraryupgrader aka LibUp
# https://www.mediawiki.org/wiki/Libraryupgrader
#
class libraryupgrader(
    Optional[Stdlib::Unixpath] $base_dir = undefined
){
    $data_dir  = "${base_dir}/data"
    $clone_dir  = "${base_dir}/libraryupgrader"

    apt::package_from_component { 'thirdparty-kubeadm-k8s':
        component => 'thirdparty/kubeadm-k8s-1-15',
        packages  => ['docker-ce'],
    }

    require_package([
        'virtualenv',
        'rabbitmq-server',
    ])

    if os_version('debian == buster') {
        # We need iptables 1.8.3+ for compatibility with docker
        # (see comments on <https://gerrit.wikimedia.org/r/565752>)
        apt::pin { 'iptables':
            pin      => 'release a=buster-backports',
            package  => 'iptables',
            priority => '1001',
            before   => Package['docker-ce'],
        }
    }

    file { $data_dir:
        ensure => directory,
        owner  => 'libup',
        group  => 'libup',
        mode   => '0755',
    }

    group { 'libup':
        ensure => present,
        name   => 'libup',
        system => true,
    }

    user { 'libup':
        ensure  => present,
        system  => true,
        groups  => 'docker',
        require => Package['docker-ce'],
    }

    git::clone {'labs/libraryupgrader':
        ensure    => present,
        directory => $clone_dir,
        branch    => 'master',
        require   => User['libup'],
        owner     => 'libup',
        group     => 'libup',
    }

    # Create virtualenv
    exec { 'create virtualenv':
        command => '/usr/bin/virtualenv -p python3 venv',
        cwd     => $clone_dir,
        user    => 'libup',
        creates => "${clone_dir}/venv/bin/python",
        require => Git::Clone['labs/libraryupgrader'],
    }

    # Bootstrap initial dependencies
    exec { 'install virtualenv dependencies':
        command => "${clone_dir}/venv/bin/pip install -r requirements.txt",
        cwd     => $clone_dir,
        user    => 'libup',
        # Just one example file created after the deps are installed
        creates => "${clone_dir}/venv/bin/gunicorn",
        require => Exec['create virtualenv'],
    }
}
