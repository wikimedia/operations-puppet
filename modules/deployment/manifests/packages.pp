class deployment::packages {
    include ::redis::client::python

    if ! defined(Package['git-core']){
      package { 'git-core':
        ensure => present,
      }
    }
    if ! defined(Package['git-fat']){
      package { 'git-fat':
        ensure => present,
      }
    }
}
