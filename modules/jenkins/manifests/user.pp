class jenkins::user {

  include jenkins::group

  systemuser { 'jenkins':
    name       => 'jenkins',
    home       => '/var/lib/jenkins',
    managehome => false,
    shell      => '/bin/bash',
  }

}
