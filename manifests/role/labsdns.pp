class role::labsdns {
    include passwords::pdns

    class { '::labs_dns':
        dns_auth_ipaddress      => '208.80.154.12',
        dns_auth_query_address  => '208.80.154.12',
        dns_auth_soa_name       => 'labs-ns2.wikimedia.org',
        pdns_db_host            => 'm1-master.eqiad.wmnet',
        pdns_db_password        => $passwords::pdns::db_pass,
        pdns_recursor           => '208.80.154.239',
        recursor_ip_range       => '10.68.16.0/21',
    }
}
