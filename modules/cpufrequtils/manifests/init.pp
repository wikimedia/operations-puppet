class cpufrequtils (
    $governor = 'performance',
) {
    package { 'cpufrequtils':
        ensure => present,
    }

    # start at boot
    service { 'cpufrequtils':
        enable  => true,
        require => Package['cpufrequtils'],
    }

    # Ubuntu's default initscripts package includes a service called "ondemand"
    #   which is a one-shot action invoked at startup which sleeps 60 seconds
    #   and then sets all CPUs to the ondemand governor, thus undoing the work
    #   of cpufrequtils. Debian has no such stupidity.
    if $::operatingsystem == 'Ubuntu' {
        service { 'ondemand':
            enable => false,
        }
    }

    file { '/etc/default/cpufrequtils':
        content => "GOVERNOR=${governor}\n",
        notify  => Exec['apply cpufrequtils'],
        require => Package['cpufrequtils'],
    }

    exec { 'apply cpufrequtils':
        command     => '/etc/init.d/cpufrequtils start',
        refreshonly => true
    }
}
