# Class for installing an Html5Depurate service
# https://www.mediawiki.org/wiki/Html5Depurate
#
# Parameters:
#     - $listen_host: The IP address or hostname to listen on. Use 0.0.0.0 for
#       a public service. Note that there is no authentication.
#     - $port: The port to listen on
#     - $max_memory_mb: The maximum memory used by the Java VM, in megabytes
#
class html5depurate(
    $listen_host = '127.0.0.1',
    $port  = 4339,
    $max_memory_mb = 500
)
{
    package { 'html5depurate':
        ensure      => installed,
    }

    file { '/etc/html5depurate/html5depurate.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['html5depurate'],
        content => template('html5depurate/html5depurate.conf.erb'),
        notify  => Service['html5depurate'],
    }

    file { '/etc/html5depurate/security.policy':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['html5depurate'],
        content => template('html5depurate/security.policy.erb'),
        notify  => Service['html5depurate'],
    }

    file { '/etc/default/html5depurate':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['html5depurate'],
        content => template('html5depurate/default.erb'),
        notify  => Service['html5depurate'],
    }

    service { 'html5depurate':
        ensure  => running,
        require => Package['html5depurate'],
    }
}
