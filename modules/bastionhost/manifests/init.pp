# bastion hosts
class bastionhost {
    system::role { "bastionhost": description => "Bastion" }

    require mysql_wmf::client

    include sudo::appserver

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
