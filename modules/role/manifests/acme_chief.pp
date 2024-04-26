class role::acme_chief {
    include profile::base::production
    include profile::firewall
    include profile::nginx
    include profile::acme_chief
}
