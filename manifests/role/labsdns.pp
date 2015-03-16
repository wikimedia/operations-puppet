class role::labsdns {
    include passwords::pdns

    class { '::labs_dns':
        dns_auth_ipaddress      => '208.80.154.19 208.80.154.18',
        dns_auth_query_address  => '208.80.154.19',
        dns_auth_soa_name       => 'labs-ns0.wikimedia.org',
        pdns_db_host            => 'm1-master.eqiad.wmnet',
        pdns_db_password        => $passwords::pdns::db_pass,
    }
}
