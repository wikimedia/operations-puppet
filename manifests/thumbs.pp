class thumbs::server {
  require "thumbs::users::apache"
}

class thumbs::users {

  # this matches the values the nginx
  # user gets out of the box, except that
  # we also add it to the apache group.
  class www-data {
    user { "www-data":
      name => "www-data",
      uid => 33,
      gid => 33,
      groups => [ "apache" ],
      home => "/var/www",
      shell => "/bin/sh",
      ensure => "present",
      membership => "minimum",
      managehome => false,
      allowdupe => false,
      system => true,
      require => thumbs::groups,
    }
  }

}

class thumbs::groups {

  class www-data {
    group { "www-data":
      name => "www-data",
      gid => 33,
      ensure => "present",
      allowdupe => false,
      system => true,
    }
  }

  class apache {
    group { "apache":
      name => "apache",
      gid => 48,
      ensure => "present",
      allowdupe => false,
      system => true,
    }
  }

}
