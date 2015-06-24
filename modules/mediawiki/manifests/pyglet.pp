# == Class: mediawiki::pyglet
#
# Configures a standalone web-service for Pygments, the syntax highlighter
# used by the SyntaxHighlight_GeSHi extension.
#
class mediawiki::pyglet(
    listen_port = 31337,
) {
    require_package('python-flask')
    require_package('python-gevent')
    require_package('python-pygments')

    file { '/srv/pyglet':
        source => 'puppet:///modules/mediawiki/pyglet',
        owner  => 'root',
        group  => 'root',
        mode   => '0775',
    }

    file { '/etc/init/pyglet.conf':
        content => template('mediawiki/pyglet/upstart.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['pyglet'],
    }

    service { 'pyglet':
        ensure   => 'running',
        provider => 'upstart',
    }
}
