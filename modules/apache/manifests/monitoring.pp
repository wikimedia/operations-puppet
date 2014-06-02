# == Class: apache::monitoring
#
# Provisions a Ganglia metric module for monitoring Apache.
#
class apache::monitoring {
    file { '/usr/lib/ganglia/python_modules/apache_status.py':
        source  => 'puppet:///modules/apache/apache_status.py',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['ganglia-monitor'],
    }

    file { '/etc/ganglia/conf.d/apache_status.pyconf':
        source  => 'puppet:///modules/apache/apache_status.pyconf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File['/usr/lib/ganglia/python_modules/apache_status.py'],
        notify  => Service['gmond'],
    }
}
