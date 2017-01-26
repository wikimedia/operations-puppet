# === Class ferm::ipsec_allow
#
# Installs the rules needed to allow the all IPsec traffic
#
class ferm::ipsec_allow {
    #firewall allow ipsec esp
    ferm::rule { 'ferm-ipsec-esp':
        rule   => 'proto esp { saddr $DOMAIN_NETWORKS ACCEPT; }',
    }

    #firewall allow ipsec ike udp 500
    ferm::service { 'ferm-ipsec-ike':
        proto  => 'udp',
        port   => '500',
        srange => '$DOMAIN_NETWORKS',
    }

}
