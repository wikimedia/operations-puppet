# analytics servers (RT-1985)

@monitor_group { 'analytics-eqiad': description => 'analytics servers in eqiad' }

# Base class for all analytics nodes.
# All analytics nodes should include this.
class role::analytics {
    system::role { 'role::analytics': description => 'analytics server' }
    $nagios_group = 'analytics-eqiad'
    # ganglia cluster name.
    $cluster = "analytics"

    package { 'openjdk-7-jdk': }

    include standard
    include admins::roots
    # Include stats system user to
    # run automated jobs and for file
    # ownership.
    include misc::statistics::user
}

# == Class role::analytics::common
# Includes common client classes for
# working with hadoop and other analytics services.
#
class role::analytics::common {
    include role::analytics

    # Include Hadoop ecosystem client classes.
    include role::analytics::hadoop::client,
        role::analytics::hive::client,
        role::analytics::oozie::client,
        role::analytics::pig,
        role::analytics::sqoop

    # We want to be able to geolocate IP addresses
    include geoip
    # udp-filter is a useful thing!
    include misc::udp2log::udp_filter
    # include dclass for device classification
    include role::analytics::dclass

    # Include Kraken repository deployments.
    include role::analytics::kraken
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
        accounts::yurik,     # RT 5158
        accounts::spetrea,   # RT 4402
        accounts::ram,       # RT 5059
        accounts::maryana,   # RT 5017
        accounts::halfak,    # RT 5233
        accounts::abaso,     # RT 5273
        accounts::qchris,    # RT 5403
        accounts::tnegrin,   # RT 5391
        accounts::ironholds, # RT 5831
        accounts::dartar,    # RT 5835
        accounts::halfak,    # RT 5836
        accounts::ypanda     # RT 6103

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


class role::analytics::dclass {
    # install dclass JNI package
    # for device classification.
    if !defined(Package['libdclass-java']) {
        package { 'libdclass-java':
            ensure  => 'installed',
        }
    }
    # Symlink libdclass* .so into /usr/lib.
    # (Oracle java does not support multiarch.)
    file { '/usr/lib/libdclass.so':
        ensure => 'link',
        target => '/usr/lib/x86_64-linux-gnu/libdclass.so.0',
        require => Package['libdclass-java'],
    }
    file { '/usr/lib/libdclassjni.so':
        ensure => 'link',
        target => '/usr/lib/x86_64-linux-gnu/jni/libdclassjni.so',
        require => Package['libdclass-java'],
    }
}

