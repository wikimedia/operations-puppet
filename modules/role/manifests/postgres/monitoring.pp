class postgres::monitoring {

  # Check that postgres is listening
  monitoring::service { 'postgres-tcp':
    description   => 'Postgres TCP port',
    check_command => "check_tcp_ip!${::ipaddress}!5432",
    contact_group => 'admins',
  }

}
