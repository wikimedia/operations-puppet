# analytics servers (RT-1985)

@monitor_group { 'analytics-eqiad': description => 'analytics servers in eqiad' }

class role::analytics {
    system_role { 'role::analytics': description => 'analytics server' }
    $nagios_group = 'analytics-eqiad'
    # ganglia cluster name.
    $cluster = "analytics"

    include standard
    include admins::roots

    # Include stats system user to
    # run automated jobs and for file
    # ownership.
    include misc::statistics::user

    # include analytics user accounts
    include role::analytics::users

    # include common analytics packages
    include role::analytics::packages

    # Include these common classes on all analytics nodes.
    # (for now we only include these on reinstalled and
    #  fully puppetized nodes.)
    if ($hostname =~ /analytics10(1[8-9]|20)/) {
        include role::analytics::pig
        include role::analytics::hive
        include role::analytics::sqoop
    }
}

class role::analytics::users {
    # Analytics user accounts will be added to the
    # 'stats' group which gets created by this class.
    require misc::statistics::user

    include accounts::diederik,
        accounts::dsc,
        accounts::otto,
        accounts::dartar,
        accounts::erosen,
        accounts::olivneh,
        accounts::erik,
        accounts::milimetric,
        accounts::yurik,    # RT 5158
        accounts::spetrea,  # RT 4402
        accounts::ram,      # RT 5059
        accounts::maryana,  # RT 5017
        accounts::halfak,   # RT 5233
        accounts::abaso,    # RT 5273
        accounts::qchris    # RT 5403

    # add Analytics team members to the stats group so they can
    # access data group owned by 'stats'.
    User<|title == milimetric|>  { groups +> [ "stats" ] }
    User<|title == yurik|>       { groups +> [ "stats" ] }
    User<|title == dartar|>      { groups +> [ "stats" ] }
    User<|title == dsc|>         { groups +> [ "stats" ] }
    User<|title == diederik|>    { groups +> [ "stats" ] }
    User<|title == erik|>        { groups +> [ "stats" ] }
    User<|title == erosen|>      { groups +> [ "stats" ] }
    User<|title == olivneh|>     { groups +> [ "stats" ] }
    User<|title == otto|>        { groups +> [ "stats" ] }
    User<|title == spetrea|>     { groups +> [ "stats" ] }
    User<|title == abaso|>       { groups +> [ "stats" ] }
    User<|title == qchris|>      { groups +> [ "stats" ] }
    

    # Diederik, David and Otto have sudo privileges on Analytics nodes.
    sudo_user { [ "diederik", "dsc", "otto" ]: privileges => ['ALL = (ALL) NOPASSWD: ALL'] }
}

# includes packages common to analytics nodes
class role::analytics::packages {
    # include java on all analytics servers
    include role::analytics::java
    # We want to be able to geolocate IP addresses
    include misc::geoip
    # udp-filter is a useful thing!
    include misc::udp2log::udp_filter

    # need python-lxml to try out check_ganglia
    # (https://github.com/larsks/check_ganglia)
    if !defined(Package['python-lxml']) {
        package { 'python-lxml':
            ensure => 'installed',
        }
    }
}



class role::analytics::java {
    # all analytics nodes need java installed
    # Install Sun/Oracle Java JDK on analytics cluster
    java { 'java-6-oracle':
        distribution => 'oracle',
        version      => 6,
    }
}


# front end interfaces for Kraken and Hadoop
class role::analytics::frontend inherits role::analytics {
    # include a mysql database for Sqoop and Oozie
    # with the datadir at /a/mysql
    class { "generic::mysql::server":
        datadir => "/a/mysql",
        version => "5.5",
    }
}

# Monitoring for kafka brokers.
class role::analytics::kafka::server inherits role::analytics {
  include misc::analytics::monitoring::kafka::server
}
