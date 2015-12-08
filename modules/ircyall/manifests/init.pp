# = Class: ircyall
#
# Sets up an ircyall instance that can take authenticated
# requests via HTTP and relay them to different IRC channels.
#
# = Parameters
# [*web_port*]
#   Port number to use for ircyall web listener
class ircyall(
    $web_port = 80,
) {

    redis::instance { 6379:
        settings => {
            appendonly     => true,
            appendfilename => "${hostname}-6379.aof",
        },
    }

    package { 'uwsgi-plugin-python3':
        ensure => present,
    }

    package { [
        'python3-flask',
        'python3-redis',
        'python3-irc3',
        'python3-asyncio-redis',
        'python3-ircyall',
    ]:
        ensure => latest
    }

    uwsgi::app { 'ircyall-web':
        settings => {
            uwsgi => {
                'plugins'   => 'python3',
                'master'    => true,
                'processes' => 8,
                'module'    => 'ircyall.web2redis',
                'callable'  => 'app',
                'socket'    => '/run/uwsgi/ircyall-web.sock',
            }
        },
        require  => Package['python3-ircyall', 'uwsgi-plugin-python3'],
    }

    nginx::site { 'ircyall-web-nginx':
        require => Uwsgi::App['ircyall-web'],
        content => template('ircyall/ircyall-web.nginx.erb'),
    }

    file { '/etc/init/ircyall.conf':
        ensure => present,
        source => 'puppet:///modules/ircyall/ircyall-upstart.conf',
    }

    service { 'ircyall':
        ensure  => running,
        require => [Package['python3-ircyall'], File['/etc/init/ircyall.conf']]
    }
}
