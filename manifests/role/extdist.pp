class role::labs::extdist {

    include role::labs::lvm::srv

    git::clone { 'labs/tools/extdist':
        directory => '/srv/extdist',
        ensure    => latest,
        branch    => 'master',
        require   => Mount['/srv']
    }

    package{ 'python-flask':
        ensure => latest
    }

    uwsgi::app { 'extdist':
        require => Git::Clone['labs/tools/extdist'],
        settings             => {
            uwsgi            => {
                'plugins'    => 'python',
                'socket'     => '/var/run/extdist.sock',
                'wsgi-file'  => '/srv/extdist/extdist.wsgi',
                'master'     => true,
                'processers' => 4,
            },
        },
    }
}
