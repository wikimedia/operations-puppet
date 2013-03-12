class base::resolving {
    if ! $::nameservers {
        error("Variable $::nameservers is not defined!")
    }
    else {
        file { "/etc/resolv.conf":
            owner => root,
            group => root,
            mode => 0444,
            content => template("base/resolv.conf.erb");
        }
    }
}
