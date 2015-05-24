class mesos::proxy {
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

    $resolver = join($::nameservers, ' ')

    nginx::site { 'event-reciever':
        content => template('mesos/marathon-event-hook.conf.erb'),
        require => File['/etc/nginx/lua/marathon-event-hook.lua'],
    }
}
