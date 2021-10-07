# Sets up the account manager for Wikimedia Meet (T251034)
class profile::meet::accountmanager(
    $clone_path = lookup('profile::meet::accountmanager::clone_path'),
    Array[Stdlib::IP::Address] $nodes = lookup('cache_hosts'),
) {

    group { 'meet-auth':
        ensure => present,
        name   => 'meet-auth',
        system => true,
    }

    user { 'meet-auth':
        home       => $clone_path,
        groups     => 'meet-auth',
        managehome => true,
        system     => true,
    }

    git::clone { 'wikimedia/meet-accountmanager':
        ensure    => present,
        directory => $clone_path,
        branch    => 'master',
        owner     => 'meet-auth',
        group     => 'meet-auth',
        require   => [User['meet-auth'], Group['meet-auth']]
    }
    ferm::service { 'meet-auth-accountmanager':
        proto  => 'tcp',
        port   => 5000,
        srange => inline_template("@resolve((<%= @nodes.join(' ') %>))"),
    }
    uwsgi::app { 'meet-accountmanager':
        settings         => {
            uwsgi => {
                'plugins'     => 'python3',
                'http-socket' => '0.0.0.0:5000',
                'wsgi-file'   => "${clone_path}/server.py",
                'callable'    => 'app',
                'master'      => true,
                'processes'   => 2,
            },
        },
    }

    profile::auto_restarts::service { 'meet-accountmanager': }
}
