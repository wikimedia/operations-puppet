class role::snapshot::common {
    include ::dataset::user
    include base::firewall

    # Allow SSH from deployment hosts
    ferm::rule { 'deployment-ssh':
        rule   => 'proto tcp dport ssh saddr $DEPLOYMENT_HOSTS ACCEPT;',
    }
}

