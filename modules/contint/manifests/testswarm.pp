# Dummy class to keep the testswarm user on the contint box.
#
# Although we are not using testswarm as of April 2013, we might use it again.
#
# Upstream: https://github.com/jquery/testswarm
#
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
