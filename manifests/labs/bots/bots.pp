# bots.pp

class bots::motd {

    file { '/etc/motd.tail':
        ensure => 'present',
        path   => '/etc/motd.tail',
        owner  => 'root',
        group  => 'root',
        mode   => '0440',
        source => 'puppet:///files/labs/bots/motd.tail',
    }
}
