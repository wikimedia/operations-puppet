# Smokeping server

class misc::smokeping {
    system::role { "misc::smokeping": description => "Smokeping server" }

    include config

    package { "smokeping":
        ensure => latest;
    }

    package { "curl":
        ensure => latest;
    }

    service { 'smokeping':
        require => [ Package['smokeping'], File["/etc/smokeping/config.d"] ],
        subscribe => File["/etc/smokeping/config.d" ],
        ensure => running;
    }
}

class misc::smokeping::config {
    Package['smokeping'] -> Class['misc::smokeping::config']

    file { "/etc/smokeping/config.d/":
        require => Package['smokeping'],
        ensure => directory,
        recurse => true,
        owner => "root",
        group => "root",
        mode => 0444,
        source => "puppet:///files/smokeping";
    }
}
