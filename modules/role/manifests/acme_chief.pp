class role::acme_chief {
    system::role { 'acme_chief': description => 'ACME certificate manager' }
    include profile::base::production
    include profile::firewall
    include profile::nginx
    include profile::acme_chief
}
