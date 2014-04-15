# bastion hosts
class bastionhost {
    system::role { "bastionhost": description => "Bastion" }

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
