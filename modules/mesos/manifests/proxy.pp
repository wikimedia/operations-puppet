class mesos::proxy {

    require_package('lua-cjson')

    class { '::dynamicproxy':
        luahandler   => 'redundanturlproxy',
    }

    file { '/etc/nginx/lua/libcjson.lua':
        source  => 'puppet:///modules/mesos/libcjson.lua',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Class['::dynamicproxy'],
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
