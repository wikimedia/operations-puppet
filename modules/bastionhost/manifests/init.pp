# bastion hosts
class bastionhost {
    system::role { "bastionhost": description => "Bastion" }

    require mysql_wmf::client

    include sudo::appserver
    include base::firewall

    ferm::service { 'ssh':
        proto => 'tcp',
        port  => 'ssh',
    }

    package { "irssi":
        ensure => absent;
        "traceroute-nanog":
        ensure => absent;
        "traceroute":
        ensure =>latest;
        "mosh":
        ensure => present;
    }
}
