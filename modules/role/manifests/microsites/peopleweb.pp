# let users publish their own HTML in their home dirs
class role::microsites::peopleweb {

    system::role { $name: }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::base::firewall::log
    include ::profile::backup::host
    include ::profile::microsites::peopleweb
}

