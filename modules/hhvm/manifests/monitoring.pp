# == Class: hhvm::monitoring
#
# Provisions Ganglia metric-gathering modules for HHVM.
#
class hhvm::monitoring {
    include ::ganglia

    ## Memory statistics

    file { '/usr/lib/ganglia/python_modules/hhvm_mem.py':
        source  => 'puppet:///modules/hhvm/monitoring/hhvm_mem.py',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => Package['ganglia-monitor'],
    }

    file { '/etc/ganglia/conf.d/hhvm_mem.pyconf':
        source  => 'puppet:///modules/hhvm/monitoring/hhvm_mem.pyconf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File['/usr/lib/ganglia/python_modules/hhvm_mem.py'],
        notify  => Service['ganglia-monitor'],
    }


    ## Health statistics

    file { '/usr/lib/ganglia/python_modules/hhvm_health.py':
        source  => 'puppet:///modules/hhvm/monitoring/hhvm_health.py',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => Package['ganglia-monitor'],
    }

    file { '/etc/ganglia/conf.d/hhvm_health.pyconf':
        source  => 'puppet:///modules/hhvm/monitoring/hhvm_health.pyconf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File['/usr/lib/ganglia/python_modules/hhvm_health.py'],
        notify  => Service['ganglia-monitor'],
    }
}
