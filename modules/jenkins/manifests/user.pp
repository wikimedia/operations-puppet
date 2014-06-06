class jenkins::user {

  include jenkins::group

  user { 'jenkins':
    home       => '/var/lib/jenkins',
    shell      => '/bin/bash',  # admins need to be able to login
    gid        => 'jenkins',
    system     => true,
    managehome => false,
    require    => Group['jenkins'];
  }
}
