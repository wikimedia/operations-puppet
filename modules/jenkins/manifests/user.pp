class jenkins::user {

  include jenkins::group

  $JENKINS_HOME = '/var/lib/jenkins'

  user { 'jenkins':
    name       => 'jenkins',
    home       => $JENKINS_HOME,
    shell      => '/bin/bash',
    gid        =>  'jenkins',
    system     => true,
    managehome => false,
    require    => Group['jenkins'],
  }

  Ssh_authorized_key {
    require => User['jenkins']
  }

  ssh_authorized_key {
    'jenkins@gallium':
      ensure  => present,
      user    => 'jenkins',
      type    => 'ssh-rsa',
      key     => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA4QGc1Zs/S4s7znEYw7RifTuZ4y4iYvXl5jp5tJA9kGUGzzfL0dc4ZEEhpu+4C/TixZJXqv0N6yke67cM8hfdXnLOVJc4n/Z02uYHQpRDeLAJUAlGlbGZNvzsOLw39dGF0u3YmwDm6rj85RSvGqz8ExbvrneCVJSaYlIRvOEKw0e0FYs8Yc7aqFRV60M6fGzWVaC3lQjSnEFMNGdSiLp3Vl/GB4GgvRJpbNENRrTS3Te9BPtPAGhJVPliTflVYvULCjYVtPEbvabkW+vZznlcVHAZJVTTgmqpDZEHqp4bzyO8rBNhMc7BjUVyNVNC5FCk+D2LagmIriYxjirXDNrWlw==',
      target  => "${JENKINS_HOME}/.ssh/authorized_keys",
      # Lame restriction from gallium
      options => [ 'from=208.80.154.191' ],

  }

}
