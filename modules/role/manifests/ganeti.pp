# Role classes for ganeti
class role::ganeti {
    include profile::base::production
    include profile::ganeti
    include profile::firewall
}
