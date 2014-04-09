# == Class: uwsgi
#
# uWSGI is a web application server, typically used in conjunction with
# Nginx to serve Python web applications, but capable of interoperating
# with a broad range of languages, protocols, and platforms.
#
class uwsgi {
    # There are 30+ uWSGI plug-ins, installable via the dependency package
    # 'uwsgi-plugins-all'. But I'm going to go out on a limb here and predict
    # that we won't use any except these two.  -- OL
    $plugins = [ 'uwsgi-plugin-python', 'uwsgi-plugin-rack-ruby1.9.1' ]

    package { [ 'uwsgi', 'uwsgi-dbg' ]: }
    package { $plugins: }

    exec { 'remove_uwsgi_initd':
        command => '/usr/sbin/update-rc.d -f uwsgi remove',
        onlyif  => '/usr/sbin/update-rc.d -n -f uwsgi remove | /bin/grep -Pq rc..d',
        require => Package['uwsgi'],
    }

    file { [ '/etc/uwsgi/apps-available', '/etc/uwsgi/apps-enabled' ]:
        ensure  => directory,
        recurse => true,
        purge   => true,
        force   => true,
        require => Package['uwsgi', $plugins],
        notify  => Service['uwsgi'],
    }

    file { '/etc/init/uwsgi':
        source  => 'puppet:///modules/uwsgi/init',
        recurse => true,
        purge   => true,
        force   => true,
        require => Package['uwsgi'],
    }

    file { '/sbin/mwprofctl':
        source  => 'puppet:///modules/mwprof/mwprofctl';
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => File['/etc/init/uwsgi'],
    }

    service { 'uwsgi':
        ensure   => 'running',
        provider => 'base',
        restart  => '/sbin/uwsgictl restart',
        start    => '/sbin/uwsgictl start',
        status   => '/sbin/uwsgictl status',
        stop     => '/sbin/uwsgictl stop',
        require  => File['/sbin/uwsgictl'],
    }
}
