# = Class: toollabs::checker
#
# Exposes a set of web endpoints that perform an explicit check for a
# particular set of internal services, and response OK (200) or not (anything else)
# Used for external monitoring / collection of availability metrics
#
# This runs as an ldap user, toolschecker, so it can touch NFS without causing
# idmapd related issues.
class toollabs::checker {
    include toollabs::infrastructure

    require_package('python-flask', 'python-redis')

    file { '/usr/local/lib/python2.7/dist-packages/toolschecker.py':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/toollabs/toolschecker.py',
    }

    uwsgi::app { 'toolschecker':
        require => File['/usr/local/lib/python2.7/dist-packages/toolschecker.py'],
        settings => {
            uwsgi => {
                'socket'    => '/run/uwsgi/toolschecker.sock',
                'plugin'    => 'python',
                'callable'  => 'app',
                'workers'   => 4,
                'master'    => 'true',
                'wsgi-file' => '/usr/local/lib/python2.7/dist-packages/toolschecker.py',
                'uid'       => 'tools.toolschecker',
            }
        }
    }

    nginx::site { 'toolschecker-nginx':
        require => Uwsgi::App['toolschecker'],
        content => template('toollabs/toolschecker.nginx.erb'),
    }
}
