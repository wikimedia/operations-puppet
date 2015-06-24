# == Class: mediawiki::pyglet
#
# Configures a standalone web-service for Pygments, the syntax highlighter
# used by the SyntaxHighlight_GeSHi extension.
#
# === Parameters
#
# [*listen_port*]
#   Port on which service should listen (default: 31337).
#
class mediawiki::pyglet( $listen_port = 31337 ) {
    require_package('python-flask')
    require_package('python-gevent')
    require_package('python-pygments')

    package { 'syntaxhighlight_geshi':
        ensure   => latest,
        provider => 'trebuchet',
        notify   => Service['pyglet'],
    }

    file { '/etc/init/pyglet.conf':
        content => template('mediawiki/pyglet/upstart.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['pyglet'],
    }

    # service { 'pyglet':
    #     ensure   => 'running',
    #     provider => 'upstart',
    # }
}
