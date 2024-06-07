class role::acme_chief::cloud {
    include profile::base::production
    include profile::firewall
    include profile::acme_chief
    include profile::acme_chief::cloud
}

