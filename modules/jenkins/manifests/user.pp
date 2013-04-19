class jenkins::user {

  systemuser { 'jenkins':
    name       => 'jenkins',
    home       => '/var/lib/jenkins',
    managehome => false,
    shell      => '/bin/bash',
  }

}
