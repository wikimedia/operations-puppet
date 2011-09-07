# mobile.pp

class mobile {
    include mobile::config
    include mobile::service::memcached
    include mobile::service::apache
}

class mobile::disabled {
    include mobile::config
    include mobile::service::memcached
}
    
class mobile::config {
  
    # Determine the number of CPU and defines the ppsize variable used by the apache2.conf.erb template.
    $ppsize = 200
    $maxclients = 250 

    # Installing required packages.
    package {
      ["ruby1.9.1", "rubygems1.9.1", "rake", "build-essential", "libxml2", "libxml2-dev", "curl", "libcurl3", "apache2", "apache2-mpm-prefork", "git-core" ]:
              ensure => latest;
      [ "ruby1.9.1-dev", "libopenssl-ruby", "apache2-prefork-dev", "mysql-server", "mysql-client", "libopenssl-ruby1.9.1", "libcurl4-openssl-dev", "libxslt-dev"]:
              ensure => latest;
      "memcached":
              ensure => installed;          
      "bundler":
              provider => gem,
              ensure => "0.9.5",
              require => Exec[gem-alternatives];
      "passenger-enterprise-server-2.9.2-1":
              provider => gem,
              require =>File["/home/deploy/passenger-enterprise-server-2.9.2-latest.gem"],
              source => "/home/deploy/passenger-enterprise-server-2.9.2-latest.gem";
    } 

  
    include mobile::users

    # Adding configuration files for Passenger and Apache
    file {
      "/srv": 
        ensure => "directory", 
        owner => "deploy", 
        group => 500, 
        mode => 0755;
        
      "/etc/apache2/sites-enabled/mobile": 
        ensure => present, 
        require => Package["apache2"], 
        source => "puppet:///files/mobile/mobile_httpd.conf";

      "/etc/apache2/sites-enabled/redirect": 
        ensure => present, 
        require => Package["apache2"], 
        source => "puppet:///files/mobile/redirect_httpd.conf";
        
      "/etc/apache2/sites-enabled/000-default": 
        ensure => present, 
        require => Package["apache2"], 
        source => "puppet:///files/mobile/default_httpd.conf";
        
      "/home/deploy/passenger-enterprise-server-2.9.2-latest.gem": 
        ensure => present, 
        require => Package["rubygems1.9.1"], 
        source => "puppet:///files/mobile/passenger-enterprise-server-2.9.2-latest.gem";
      
      # This one is kind of a hack, and there must be an easier way to puppetize it. 
      # I will look at it later. 
      "/home/deploy/passenger_install.sh": 
        ensure => present, 
        require => File["/home/deploy/passenger-enterprise-server-2.9.2-latest.gem"], 
        source => "puppet:///files/mobile/passenger_install.sh", owner => "root", mode => 0700;
      
      "/etc/logrotate.d/mobile": 
        ensure => present, 
        source => "puppet:///files/mobile/mobile.logrotate", 
        owner => "root", mode => 0644;
      
      "/etc/logrotate.d/apache2": 
        ensure => present, 
        source => "puppet:///files/mobile/apache2.logrotate", 
        owner => "root", 
        mode => 0644;
      
      "/etc/memcached.conf": 
        ensure => present, 
        require => Package["memcached"], 
        source => "puppet:///files/mobile/memcached.conf", 
        owner => "root", 
        mode => 0644;
      
      "/etc/apache2/apache2.conf": 
        ensure => present, 
        require => Package["apache2"], 
        content => template("mobile/apache2.conf.erb"), 
        owner => "root", 
        mode => 0644;
      
      "/etc/apache2/mods-enabled/rewrite.load": 
        require => Package["apache2"], 
        ensure => "../mods-available/rewrite.load";
    } 
    
    
    # Running some setup scripts. 
    exec {
      gem-alternatives:
        command     => "/usr/sbin/update-alternatives --set gem /usr/bin/gem1.9.1",
        require     => Package["rubygems1.9.1"];
      
      passenger_install:
        command     => "/home/deploy/passenger_install.sh",
        subscribe   => File["/home/deploy/passenger-enterprise-server-2.9.2-latest.gem"],
        refreshonly => true,
        require     => File["/home/deploy/passenger_install.sh"];
    }

        # Tune kernel settings
        include generic::sysctl::high-http-performance

}

# making sure some basic services are running.
class mobile::service::memcached {
    service {
      memcached: 
        require     => Package["memcached"],
        ensure      => running;
    }
}

class mobile::service::apache {
    service {
      apache2:
        require     => Package["apache2"],
        ensure      => running;
    } 
}

class mobile::users {

    # Create a default deploy user to be use by capistrano to deploy ruby code in /srv/...
    user {
      "deploy":
        ensure      => "present",
        gid         => 500,
        managehome  => true,
        shell       => "/bin/bash";
    }
    
    # Capistrano needs to be able to log into the mobile servers in order to deploy code.
    # -- This is Hcatlin's key so that he can deploy from his computer.
    ssh_authorized_key {
      "deploy@localhost":
        ensure      => "present",
        user        => deploy,
        require     => User['deploy'],
        type        => "ssh-rsa",
        key         => "AAAAB3NzaC1yc2EAAAABIwAAAQEAoET83J1YKyC8C0su4RfGVWz9Lx69dwSgPamrAGue/BvQ4W7IDvCQZPi8pKMZuhY4N7OkjjhTjV7JqMqqjKICCwFVHZQSuMbFKYbaMtuYGGno0kGVRpGd7n9x4bHAep5K6H/FUpedPPjuhfXmvl7EYRIYHJrayMS2P79o5GcFFwQ6rYuBvc/vAMkOp1NFjfOktPLUmaU4PMroeIPf1XJ+n2Wr5hFw7fehHcYF7VmJft6jhPN+DVHyziJPRWEhFe5axfkqEC6wIk2O/d7OqnPATlk+7+vEh69yOzZu8Jh/FrNn9HzGHH8ZzvuksUvVoRyw8qlhFRxJKLbl/IPPZ5v7Dw==";
    # -- And this is Fred's key so he can deploy from his computer. In a perfect world, this would be fenari
    #    But fenari is running old ubuntu that doesn't support capistrano's Gem... Will be fixed one of these days.  
      "fred@depthstar":
        ensure      => "absent",
        user        => deploy,
        require     => User['deploy'],
        type        => "ssh-rsa",
        key         => "AAAAB3NzaC1yc2EAAAABIwAAAQEAudXr3BJ9jDtPIJhZhEjk9JLynjNR/jVknQvMpDWR5mwXJJ1aicsNthxP3tYWHDMSCQnQ6Jt6lYR0Ha/QWh9PANCeNc5TAAeXuE55Etbv34sCP5EkRAwRFkQrBasTT480fA5KRxQFsA8oterA8kI65+c6IlctCHpMaVyctZPIpjpZwZDfqxGn1k0pyVdHj/z7BtMZaviLsHYbBO/+/Z4zqYFqGSWBT3dpYZu69FqYzM0jLajqV+s+UjiMmyiEe93jFG2nN2HzqiSDpjAhk/kZBdZlPHtWZclsTJUDqI2xUrqElprr8FQEd37IMCXNLh7Qv7ZXLEjd8fx6NaalEU3F4Q==";
    }
}

class mobile::v1104 {
  
    # Determine the number of CPU and defines the ppsize variable used by the apache2.conf.erb template.
    $ppsize = 250
    $maxclients = 300 

    # Installing required packages.
    package {
      ["ruby1.9.1", "rubygems1.9.1", "rake", "build-essential", "libxml2", "libxml2-dev", "curl", "libcurl3", "apache2", "apache2-mpm-prefork", "git-core" ]:
              ensure => latest;
      [ "ruby1.9.1-dev", "libopenssl-ruby", "apache2-prefork-dev", "mysql-server", "mysql-client", "libopenssl-ruby1.9.1", "libcurl4-openssl-dev", "libxslt-dev"]:
              ensure => latest;
      "memcached":
              ensure => installed;          
      "bundler":
              provider => gem,
              ensure => "1.0.14",
              require => Exec[gem-alternatives];
      "passenger":
              provider => gem,
              ensure => "3.0.7",
              require => Exec[gem-alternatives];
    } 

    include mobile::users
    
    # Adding configuration files for Passenger and Apache
    file {
      "/srv": 
        ensure => "directory", 
        owner => "deploy", 
        group => 500, 
        mode => 0755;
        
      "/etc/apache2/ports.conf": 
        ensure => present, 
        require => Package["apache2"], 
        source => "puppet:///files/mobile/ports.conf.81";

      "/etc/apache2/sites-enabled/mobile": 
        ensure => present, 
        require => Package["apache2"], 
        source => "puppet:///files/mobile/mobile_httpd.conf";

      "/etc/apache2/sites-enabled/redirect": 
        ensure => present, 
        require => Package["apache2"], 
        source => "puppet:///files/mobile/redirect_httpd.conf";
        
      "/etc/apache2/sites-enabled/000-default": 
        ensure => present, 
        require => Package["apache2"], 
        source => "puppet:///files/mobile/default_httpd.conf";
        
      "/etc/default/varnish":
        ensure => present, 
        source => "puppet:///files/mobile/default_ruby_varnish";

      "/etc/varnish/ruby_mobile.vcl":
        ensure => present, 
        source => "puppet:///files/mobile/ruby_mobile.vcl";

      # This one is kind of a hack, and there must be an easier way to puppetize it. 
      # I will look at it later. 
      "/home/deploy/passenger_install.sh": 
        ensure => present, 
        source => "puppet:///files/mobile/passenger_install.sh", owner => "root", mode => 0700;
      
      "/etc/logrotate.d/mobile": 
        ensure => present, 
        source => "puppet:///files/mobile/mobile.logrotate", 
        owner => "root", mode => 0644;
      
      "/etc/logrotate.d/apache2": 
        ensure => present, 
        source => "puppet:///files/mobile/apache2.logrotate", 
        owner => "root", 
        mode => 0644;
      
      "/etc/memcached.conf": 
        ensure => present, 
        require => Package["memcached"], 
        source => "puppet:///files/mobile/memcached.conf", 
        owner => "root", 
        mode => 0644;
      
      "/etc/apache2/apache2.conf": 
        ensure => present, 
        require => Package["apache2"], 
        content => template("mobile/apache2.conf.erb"), 
        owner => "root", 
        mode => 0644;
      
      "/etc/apache2/mods-enabled/rewrite.load": 
        require => Package["apache2"], 
        ensure => "../mods-available/rewrite.load";
    } 
    
    
    include mobile::service::memcached
    include mobile::service::apache

    # Running some setup scripts. 
    exec {
      gem-alternatives:
        command     => "/usr/sbin/update-alternatives --install /usr/bin/gem gem /usr/bin/gem1.9.1 1",
        require     => Package["rubygems1.9.1"];
      
      passenger_install:
        command     => "/home/deploy/passenger_install.sh",
        refreshonly => true,
        require     => File["/home/deploy/passenger_install.sh"];
    }

        # Tune kernel settings
        include generic::sysctl::high-http-performance

}
