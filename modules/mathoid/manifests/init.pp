# == Class: mathoid
#
# mathoid is a node.js backend for the math rendering.
#
# === Parameters
#
# [*base_path*]
#   Path to the mathoid code.
# [*node_path*]
#   Path to the node modules mathoid depends on.
# [*conf_path*]
#   Where to place the config file.
# [*log_dir*]
#   Place where mathoid can put log files. Assumed to be already existing and
#   have write access to mathoid user.
# [*port*]
#   Port where to run the mathoid service. Defaults to 10042.
#
class mathoid(
    $base_path,
    $node_path,
    $conf_path,
    $log_dir,
    $port=10042
) {
    ensure_packages( ['nodejs'] )
    # TODO Add dependency to node-jsdom once
    # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=742347
    # is fixed

    $log_file = "${log_dir}/main.log"

    file { $log_dir:
        ensure => directory,
        owner  => mathoid,
        group  => mathoid,
        mode   => '0775',
    }

    file { $conf_path:
        ensure  => present,
        owner   => mathoid,
        group   => mathoid,
        mode    => '0555',
        content => template('mathoid/config.erb'),
    }

    # The upstart configuration
    file { '/etc/init/mathoid.conf':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        content => template('mathoid/upstart.erb'),
    }

    file { '/etc/logrotate.d/mathoid':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        content => template('mathoid/logrotate.erb'),
    }

    service { 'mathoid':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        provider   => 'upstart',
        require    => File[$log_dir],
        subscribe  => File['/etc/init/mathoid.conf'],
    }
}
