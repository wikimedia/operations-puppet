# SSH module

class ssh {
  case $::operatingsystem {
    debian, ubuntu: {
    }
    default: {
      fail("Module ${module_name} is not supported on ${::operatingsystem}")
    }
  }

  include ssh::client
  include ssh::server
}
