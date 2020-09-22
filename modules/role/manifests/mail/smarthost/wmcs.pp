class role::mail::smarthost::wmcs {

    system::role { 'mail::smarthost::wmcs':
        description => 'WMCS Outbound Mail Smarthost',
    }

    include ::profile::base::firewall
    include ::profile::mail::smarthost::wmcs
}
