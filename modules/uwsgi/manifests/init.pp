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
    if os_version('debian == jessie') {
        $plugins = [ 'uwsgi-plugin-python', 'uwsgi-plugin-python3', 'uwsgi-plugin-rack-ruby2.1' ]
    } elsif os_version('debian == stretch') {
        $plugins = [ 'uwsgi-plugin-python', 'uwsgi-plugin-python3', 'uwsgi-plugin-rack-ruby2.3' ]
    } elsif $::lsbdistcodename  == 'buster' { # TODO: Replace it with os_version after buster gets released
        $plugins = [ 'uwsgi-plugin-python', 'uwsgi-plugin-python3', 'uwsgi-plugin-rack-ruby2.5' ]
    }

    package { 'uwsgi': }
    package { $plugins: }

    exec { 'remove_uwsgi_initd':
        command => '/usr/sbin/update-rc.d -f uwsgi remove',
        onlyif  => '/usr/sbin/update-rc.d -n -f uwsgi remove | /bin/grep -Pq rc..d',
        require => Package['uwsgi'],
    }

    if os_version('debian >= jessie') {
        # Stop the default uwsgi service since it is incompatible with
        # our multi instance setup. The update-rc.d isn't good enough on
        # systemd instances
        service { 'uwsgi':
            ensure  => stopped,
            enable  => false,
            require => Package['uwsgi'],
        }
    }

    file { [ '/etc/uwsgi/apps-available', '/etc/uwsgi/apps-enabled' ]:
        ensure  => directory,
        recurse => true,
        purge   => true,
        force   => true,
        require => Package['uwsgi', $plugins],
    }

    file { '/run/uwsgi':
        ensure => directory,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0755',
    }

    # additionally, ensure that /run/uwsgi is created at boot
    if os_version('debian >= jessie') {
        systemd::tmpfile { 'uwsgi-startup':
            content => 'd /run/uwsgi 0755 www-data www-data',
        }
    } else {
        base::service_unit { 'uwsgi-startup':
            ensure          => present,
            upstart         => upstart_template('uwsgi-startup'),
            declare_service => false,
        }
    }
}
