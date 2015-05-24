class marathon::proxy {
    class { '::dynamicproxy':
        luahandler   => 'redundanturlproxy',
    }

    file { '/etc/nginx/lua/marathon-event-hook.lua':
        source  => 'puppet:///modules/mesos/marathon-event-hook.lua',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Class['::dynamicproxy'],
    }

    nginx::site { 'event-reciever':
        source  => 'puppet:///modules/mesos/marathon-event-hook.conf',
        require => File['/etc/nginx/lua/marathon-event-hook.lua'],
    }
}
