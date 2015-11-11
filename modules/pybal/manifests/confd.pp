# Resources required for pybal/confd interaction
#
class pybal::confd {

    file { '/etc/pybal/pools':
        ensure => directory,
        require => Package[pybal],
    }

    file { '/usr/local/bin/pybal-eval-check':
        ensure => absent,
        mode   => '0555',
        source => 'puppet:///modules/pybal/pybal-eval-check.py',
    }
}
