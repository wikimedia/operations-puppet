package {
    "apache2":
        ensure => installed;
    }



service {
    "apache2":
        ensure => running,
        require => Package["apache2"];
}



file {
    "/etc/apache2/site-available/stats.grok.se":
        ensure => present,
        owner => root,
        group => root,
        mode => 664,
        content => template("httpd.conf.erb"),
        require => Package["apache2"],
        notify => Service["apache2"];
}