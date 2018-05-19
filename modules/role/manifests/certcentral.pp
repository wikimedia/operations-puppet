class role::certcentral {
    system::role { 'certcentral': description => 'Central certificates service' }
    include ::standard
    include ::profile::base::firewall
    include ::profile::certcentral
}
