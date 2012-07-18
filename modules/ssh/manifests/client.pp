class ssh::client {
  case $::operatingsystem {
    debian, ubuntu: {
    }
    default: {
      fail("Module ${module_name} is not supported on ${::operatingsystem}")
    }
  }

  package { 'openssh-client':
    ensure => latest,
  }
}
