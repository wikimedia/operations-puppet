# == Class: mediawiki::monitor::errors
#
# Configures a metric module that listens on a UDP port for MediaWiki
# fatal and exception log messages and reports them to Ganglia.
#
# === Parameters
#
# [*port*]
#   UDP port on which metric module should listen (default: 8423).
#
# [*ensure*]
#   If 'present' (the default), provisions the metric module. If
#   'absent', removes the module source and configuration files.
#
# === Examples
#
#  class { 'mediawiki::monitor::errors':
#      ensure => present,
#      port   => 9400,
#  }
#
class mediawiki::monitor::errors(
    $ensure = present,
    $port   = 8423,
) {
    # Metric module.
    file { '/usr/lib/ganglia/python_modules/mwerrors.py':
        ensure => $ensure,
        source => 'puppet:///modules/mediawiki/mwerrors.py',
        before => File['/etc/ganglia/conf.d/mwerrors.pyconf'],
    }

    # Metric definitions.
    file { '/etc/ganglia/conf.d/mwerrors.pyconf':
        ensure  => $ensure,
        content => template('mediawiki/mwerrors.pyconf.erb'),
        notify  => Service['gmond'],
    }
}
