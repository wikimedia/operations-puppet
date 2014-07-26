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
        require              => [Git::Clone['labs/tools/extdist'], Package['pyton-flask']],
        settings             => {
            uwsgi            => {
                'socket'     => '/var/run/extdist.sock',
                'wsgi-file'  => '/srv/extdist/extdist.wsgi',
                'master'     => true,
                'processers' => 4,
                'chdir'      => '/srv/extdist',
            },
        },
    }
}
