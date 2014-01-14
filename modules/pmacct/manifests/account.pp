# Sets up a user, group and home directory for pmacct

class pmacct::account {
  $user  = 'pmacct'
  $group = 'pmacct'
  $home  = '/srv/pmacct'

  user { $user:
    ensure     => present,
    gid        => $group,
    home       => $home,
    system     => true,
    managehome => true,
  }
  group { $group:
    ensure     => 'present',
  }

}
