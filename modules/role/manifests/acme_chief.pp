class role::acme_chief {
    system::role { 'acme_chief': description => 'ACME certificate manager' }
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::base::firewall::log
    include ::profile::acme_chief
}
