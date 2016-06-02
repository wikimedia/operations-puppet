# http://apt.wikimedia.org/wikimedia/
class role::aptrepo::wikimedia {

    class { '::aptrepo':
        basedir => '/srv/wikimedia',
    }

    file { "${basedir}/conf/distributions":
        ensure => present,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/aptrepo/distributions-wikimedia',
    }

}
