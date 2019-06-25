# == Class cdh::impala::worker
# Installs and runs impalad server.
# You should probably include this on all your Hadoop worker nodes
#
class cdh::impala::worker inherits cdh::impala {
    package {'impala-server':
        ensure => 'installed',
    }

    # Impala uses cgroups to manage resources.
    # Create a cgroup mount in which to Impala will manage its CPU cgroups
    $cgroup_path = '/sys/fs/cgroup/cpu/impala'

    # Installing cgroup-bin to have cgroups mounted in /sys/fs/cgroup
    # and allow us to use cgcreate to create a CPU cgroup for Impala.
    package { 'cgroup-bin':
        ensure => 'installed',
    }
    exec { 'cgroup-create-impala':
        command => '/usr/bin/cgcreate -a impala:impala -t impala:impala  -g cpu:impala',
        creates => "${cgroup_path}/tasks",
        require => [Package['impala-server'], Package['cgroup-bin']],
    }

    $hadoop_config_directory = $::cdh::hadoop::config_directory
    $fair_scheduler_enabled = $::cdh::hadoop::fair_scheduler_enabled

    file { '/etc/default/impala':
        content => template('cdh/impala/default-impala.erb'),
        require => Package['impala-server'],
    }

    service { 'impala-server':
        ensure     => 'running',
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
        require    => [
            Package['impala-server'],
            Exec['cgroup-create-impala'],
            File['/etc/default/impala'],
        ]
    }
}
