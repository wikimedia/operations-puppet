# @!visibility private
class postfix::install {

  package { $postfix::package_name:
    ensure => present,
  }
}
