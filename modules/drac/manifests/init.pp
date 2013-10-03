class drac {
    package {'python-paramiko':
        ensure      => latest,
    }

    file {'/usr/local/sbin/drac':
            owner   => root,
            group   => root,
            mode    => '0555',
            source  => 'puppet:///modules/drac/drac.py',
            require => Package['python-paramiko'],
    }
}
