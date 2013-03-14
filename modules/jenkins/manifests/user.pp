class jenkins::user {

  include jenkins::group

  systemuser { 'jenkins':
    name       => 'jenkins',
    home       => '/var/lib/jenkins',
    managehome => false,
    shell      => '/bin/bash',
    gid        =>  'jenkins',
    require    => Group['jenkins'];
  }

}
