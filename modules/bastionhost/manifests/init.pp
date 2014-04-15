# bastion hosts
class bastionhost {
    system::role { "bastionhost": description => "Bastion" }

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
