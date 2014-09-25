# == Class: citoid
#
# citoid is a node.js backend for citation lookups.
#
# === Parameters
#
# [*base_path*]
#   Path to the citoid code.
# [*node_path*]
#   Path to the node modules citoid depends on.
# [*log_dir*]
#   Place where citoid can put log files. Assumed to be already existing and
#   have write access to citoid user.
# [*port*]
#   Port where to run the citoid service. Defaults to 1970.
#
class citoid(
    $base_path,
    $node_path,
    $log_dir,
    $port=1970
) {
    ensure_packages( ['nodejs'] )

    $log_file = "${log_dir}/main.log"

    file { $log_dir:
        ensure => directory,
        owner  => 'citoid',
        group  => 'citoid',
        mode   => '0775',
    }

    # The upstart configuration
    file { '/etc/init/citoid.conf':
        content => template('citoid/upstart.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    file { '/etc/logrotate.d/citoid':
        content => template('citoid/logrotate.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    service { 'citoid':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        provider   => 'upstart',
        require    => File[$log_dir],
        subscribe  => File['/etc/init/citoid.conf'],
    }
}
