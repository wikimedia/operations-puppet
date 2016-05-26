class postgresql::monitoring(
  $contact_group = 'admins',
) {

  # Check that postgres is running
  # this requires the nagios user to be able to access template1 without password
  nrpe::monitor_service { 'postgres':
    description   => 'Postgres',
    nrpe_command  => '/usr/lib/nagios/plugins/check_pgsql',
    contact_group => $contact_group,
  }

}
