class contint::testswarm {

  # Create a user to run the cronjob with
  systemuser { 'testswarm':
    name   => 'testswarm',
    home   => '/var/lib/testswarm',
    shell  => '/bin/false',
    # And part of web server user group so we can let it access
    # the SQLite databases
    groups => [ 'www-data' ];
  }

}
