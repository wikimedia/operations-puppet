define deployment::target($ensure=present) {
    salt::grain { "deployment_target_$name":
        ensure => $ensure,
        grain  => "deployment_target",
        value  => $name;
    }
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
