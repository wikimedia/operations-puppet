class exim::role::simple-mail-sender {
    class { "config": queuerunner => "queueonly" }
    Class["config"] -> Class[exim::role::simple-mail-sender]

    file {
        "/etc/exim4/exim4.conf":
            require => Package[exim4-config],
            owner => root,
            group => root,
            mode => 0444,
            content => template("exim/exim4.minimal.erb");
    }

    include service
}
