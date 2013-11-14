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

    service { 'uwsgi':
        ensure   => running,
        enable   => true,
        provider => 'debian',
        require  => Package['uwsgi'],
    }

    file { [ '/etc/uwsgi/apps-available', '/etc/uwsgi/apps-enabled' ]:
        ensure  => directory,
        recurse => true,
        purge   => true,
        force   => true,
        require => Package['uwsgi', $plugins],
        notify  => Service['uwsgi'],
    }
}
