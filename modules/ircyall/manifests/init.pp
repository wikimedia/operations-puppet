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

    class { 'redis':
        persist => 'aof',
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
                'socket'    => '/run/uwsgi/ircyall-web.sock',
            }
        }
    }

    nginx::site { 'ircyall-web-nginx':
        require => Uwsgi::App['ircyall-web'],
        content => template('ircyall/ircyall-web.nginx.erb'),
    }
}
