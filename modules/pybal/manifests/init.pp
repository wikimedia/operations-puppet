class pybal {

    package { [ 'ipvsadm', 'pybal' ]:
        ensure => installed;
    }

    file { '/usr/local/bin/pybal-eval-check':
        ensure => file,
        mode   => '0555',
        source => 'puppet:///modules/pybal/pybal-eval-check.py',
    }
}
