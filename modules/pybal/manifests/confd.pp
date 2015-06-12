class pybal::confd {

    file { '/usr/local/bin/pybal-eval-check':
        ensure => file,
        mode   => '0555',
        source => 'puppet:///modules/pybal/pybal-eval-check.py',
    }
}
