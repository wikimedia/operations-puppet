class mesos::marathon::master {
    require_package('marathon')

    service { 'marathon':
        ensure => running,
    }

    file { [
        '/etc/marathon/',
        '/etc/marathon/conf',
    ]:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
}
