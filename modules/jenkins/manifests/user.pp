class jenkins::user {

  require jenkins::group

  user { 'jenkins':
    name       => 'jenkins',
    home       => '/var/lib/jenkins',
    shell      => '/bin/bash',
    gid        =>  'jenkins',
    system     => true,
    managehome => false,
    require    => Group['jenkins'];
  }

}
