define deployment::target($ensure=present) {
    salt::grain { "deployment_target_$name":
        ensure => $ensure,
        grain  => "deployment_target",
        value  => $name;
    }
}
