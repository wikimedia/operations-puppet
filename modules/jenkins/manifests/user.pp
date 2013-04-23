class jenkins::user {

  include jenkins::group

  # We do not use systemuser{} since we would like to keep
  # the group definition in the jenkins module.
  user { 'jenkins':
    name       => 'jenkins',
    home       => '/var/lib/jenkins',
    shell      => '/bin/bash',  # admins need to be able to login
    gid        => 'jenkins',
    system     => true,
    managehome => false,
    require    => Group['jenkins'];
  }

}
