# == Class: hhvm::monitoring
#
# Provisions Ganglia metric-gathering modules for HHVM.
#
class hhvm::monitoring {
    include ::ganglia

    ## Memory statistics

    file { '/usr/lib/ganglia/python_modules/hhvm_mem.py':
        source  => 'puppet:///modules/hhvm/monitoring/hhvm_mem.pyconf',
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
        notify  => Service['gmond'],
    }
}
