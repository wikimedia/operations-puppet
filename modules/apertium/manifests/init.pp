# == Class: apertium
#
# apertium is a backend service for the content translation tool.
# https://www.mediawiki.org/wiki/Content_translation/Apertium/Service
#
# === Parameters
# [*log_dir*]
#   Place where apertium can put log files. Assumed to be already existing and
#   have write access to apertium user.
# [*port*]
#   Port where to run the apertium service. Defaults to 2737.

class apertium(
    $log_dir,
    $port=2737
) {
    # apertium-* packages stays in packages.pp
    include ::apertium::packages

    $log_file = "${log_dir}/main.log"

    file { $log_dir:
        ensure => directory,
        owner  => apertium,
        group  => apertium,
        mode   => '0775',
    }

    # The upstart configuration
    file { '/etc/init/apy.conf':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        content => template('apertium/upstart.erb'),
    }

    file { '/etc/logrotate.d/apertium':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        content => template('apertium/logrotate.erb'),
    }

    service { 'apy':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        provider   => 'upstart',
        require    => File[$log_dir],
        subscribe  => File['/etc/init/apy.conf'],
    }
}
