# http://apt.wikimedia.org/wikimedia/
class role::aptrepo::wikimedia {

    $basedir = '/srv/wikimedia'

    class { '::aptrepo':
        basedir => $basedir,
    }

    file { "${basedir}/conf/distributions":
        ensure => present,
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/aptrepo/distributions-wikimedia',
    }

}
