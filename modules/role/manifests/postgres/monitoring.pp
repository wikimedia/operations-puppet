class postgres::monitoring {

  # Check that postgres is running
  # this requires the nagios user to be able to access template1 without password
  monitoring::service { 'postgres':
    description   => 'Postgres',
    check_command => '/usr/lib/nagios/plugins/check_pgsql',
    contact_group => 'admins',
  }

}
