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

    # The upstart configuration
    file { '/etc/init/apertium-apy.conf':
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

    file { '/etc/init.d/apertium-apy':
        ensure => 'link',
        target => '/lib/init/upstart-job',
    }

    service { 'apertium-apy':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        provider   => 'upstart',
        require    => [
            File[$log_dir],
            File['/etc/init.d/apertium-apy']
        ],
        subscribe  => File['/etc/init/apertium-apy.conf'],
    }
}
