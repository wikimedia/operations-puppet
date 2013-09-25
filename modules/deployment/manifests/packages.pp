class deployment::packages {
    if ! defined(Package["git-core"]){
      package { "git-core":
        ensure => present;
      }
    }
    if ! defined(Package["python-redis"]){
      package { "python-redis":
        ensure => present;
      }
    }
}
