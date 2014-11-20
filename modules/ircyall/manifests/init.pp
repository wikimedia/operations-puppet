# = Class: ircyall
#
# Sets up an ircyall instance that can take authenticated
# requests via HTTP and relay them to different IRC channels.
class ircyall {

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
                'processes' => 4, 
                'module'    => 'ircyall.web2redis',
                'http'      => '0.0.0.0:80'
            }
        }
    }
}
