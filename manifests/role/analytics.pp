# analytics servers (RT-1985)

@monitor_group { 'analytics_eqiad': description => 'analytics servers in eqiad' }

# == Class role::analytics
# Base class for all analytics nodes.
# All analytics nodes should include this.
class role::analytics {
    system::role { 'role::analytics': description => 'analytics server' }

    if !defined(Package['openjdk-7-jdk']) {
        package { 'openjdk-7-jdk':
            ensure => 'installed',
        }
    }
}

# == Class role::analytics::clients
# Includes common client classes for
# working with hadoop and other analytics services.
# This class is often included by including
# role::analytics::kraken, but you may include
# it on its own if you don't need any kraken code.
class role::analytics::clients {
    include role::analytics

    # Include Hadoop ecosystem client classes.
    include role::analytics::hadoop::client,
        role::analytics::hive::client,
        role::analytics::oozie::client,
        role::analytics::pig,
        role::analytics::sqoop
}

# == Class role::analytics::users
# Users that should be on analytics nodes.
# This class is not included on *all* analytics
# nodes, just ones where it is useful for users to
# have accounts.  I.e. hadoop related nodes.
# Users do not need accounts on Kafka or Zookeeper nodes.
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
        accounts::dr0ptp4kt, # RT 5273
        accounts::qchris,    # RT 5403
        accounts::tnegrin,   # RT 5391
        accounts::ironholds, # RT 5831
        accounts::dartar,    # RT 5835
        accounts::halfak,    # RT 5836
        accounts::yuvipanda, # RT 6103
        accounts::csalvia,   # RT 6664
        accounts::nuria,     # RT 6683
        accounts::sahar,     # RT 6767
        accounts::kleduc     # RT 7425

    # NOTE:  If you are filling an RT request for Hadoop access,
    # you will need to add the user to the list of accounts above,
    # as well as manually create the user's HDFS home directory.
    # Once the user's posix account is created on analytics1010
    # (the Hadoop NameNode), run these commands:
    #
    #   sudo -u hdfs hadoop fs -mkdir /user/<username>
    #   sudo -u hdfs hadoop fs -chown <username>:stats /user/<username>
    #

    # Users in the stats group will be able to read private data in HDFS.
    User<|title == milimetric|>  { groups +> [ 'stats' ] }
    User<|title == yurik|>       { groups +> [ 'stats' ] }
    User<|title == dartar|>      { groups +> [ 'stats' ] }
    User<|title == dsc|>         { groups +> [ 'stats' ] }
    User<|title == diederik|>    { groups +> [ 'stats' ] }
    User<|title == erik|>        { groups +> [ 'stats' ] }
    User<|title == erosen|>      { groups +> [ 'stats' ] }
    User<|title == olivneh|>     { groups +> [ 'stats' ] }
    User<|title == otto|>        { groups +> [ 'stats' ] }
    User<|title == spetrea|>     { groups +> [ 'stats' ] }
    User<|title == dr0ptp4kt|>   { groups +> [ 'stats' ] }
    User<|title == qchris|>      { groups +> [ 'stats' ] }
    User<|title == csalvia|>     { groups +> [ 'stats' ] }
    User<|title == nuria|>       { groups +> [ 'stats' ] }
    User<|title == kleduc|>      { groups +> [ 'stats' ] }

    # If hdfs user exists, then add it to the stats group.
    # I don't want to use puppet types to manage the hdfs
    # user, since it is installed by the cdh4 packages.
    exec { 'hdfs_user_in_stats_group':
        command => 'usermod hdfs -a -G stats',
        # only run this command if the hdfs user exists
        # and it is not already in the stats group
        # This command returns true if hdfs user does not exist,
        # or if hdfs user does exist and is in the stats group.
        unless  => 'getent passwd hdfs > /dev/null; if [ $? != 0 ]; then true; else groups hdfs | grep -q stats; fi',
        path    => '/usr/sbin:/usr/bin:/bin',
        require => Group['stats'],
    }

    # Diederik and Otto have sudo privileges on Analytics nodes.
    sudo_user { [ 'diederik', 'otto' ]: privileges => ['ALL = (ALL) NOPASSWD: ALL'] }
}
