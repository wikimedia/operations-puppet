# bastion hosts
class bastionhost {
    system::role { "bastionhost": description => "Bastion" }

    require mysql_wmf::client

    include base::firewall

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
