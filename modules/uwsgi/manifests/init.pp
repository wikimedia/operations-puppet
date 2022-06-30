# SPDX-License-Identifier: Apache-2.0
# == Class: uwsgi
#
# uWSGI is a web application server, typically used in conjunction with
# Nginx to serve Python web applications, but capable of interoperating
# with a broad range of languages, protocols, and platforms.
#
class uwsgi (
    Wmflib::Ensure $ensure = present,
) {
    # There are 30+ uWSGI plug-ins, installable via the dependency package
    # 'uwsgi-plugins-all'. But I'm going to go out on a limb here and predict
    # that we won't use any except these two.  -- OL
    $plugins = debian::codename() ? {
        'stretch'  => ['uwsgi-plugin-python', 'uwsgi-plugin-python3', 'uwsgi-plugin-rack-ruby2.3'],
        'buster'   => ['uwsgi-plugin-python', 'uwsgi-plugin-python3', 'uwsgi-plugin-rack-ruby2.5'],
        'bullseye' => ['uwsgi-plugin-python3', 'uwsgi-plugin-rack-ruby2.7'],
        default    => fail("${debian::codename()}: not supported"),
    }

    package { 'uwsgi':
        ensure => $ensure,
    }

    package { $plugins:
        ensure => $ensure,
    }

    if $ensure == 'present' {
        exec { 'remove_uwsgi_initd':
            command => '/usr/sbin/update-rc.d -f uwsgi remove',
            onlyif  => '/usr/bin/find /etc/rc?.d -name \'[KS][0-9][0-9]uwsgi\' | grep -q .',
            require => Package['uwsgi'],
        }

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
        ensure  => stdlib::ensure($ensure, 'directory'),
        recurse => true,
        purge   => true,
        force   => true,
        require => Package['uwsgi', $plugins],
    }

    file { '/run/uwsgi':
        ensure => stdlib::ensure($ensure, 'directory'),
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0755',
    }

    if $ensure == 'absent' {
        File['/run/uwsgi'] {
            recurse => true,
            force   => true,
        }
    }

    # additionally, ensure that /run/uwsgi is created at boot
    systemd::tmpfile { 'uwsgi-startup':
        ensure  => $ensure,
        content => 'd /run/uwsgi 0755 www-data www-data',
    }
}
