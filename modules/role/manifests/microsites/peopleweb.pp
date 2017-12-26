# let users publish their own HTML in their home dirs
class role::microsites::peopleweb {

    system::role { $name: }

    include ::standard
    include ::profile::base::firewall
    include ::profile::backup::host 
    include ::profile::microsites::peopleweb
}

