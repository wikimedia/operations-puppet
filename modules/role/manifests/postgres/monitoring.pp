class postgres::monitoring {

  # CQL query interface monitoring (T93886)
  monitoring::service { 'postgres-tcp':
    description   => 'Postgres TCP port',
    check_command => "check_tcp_ip!${::ipaddress}!5432",
    contact_group => 'admins',
  }

}
