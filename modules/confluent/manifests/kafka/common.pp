# == Class confluent::kafka::common
#
# Installs the confluent-kafka package and a handy kafka wrapper script.
#
# Most likely you will not use this class directly, and instead
# just use confluent::kafka::broker to install and start a Kafka broker.
# You will only use confluent::kafka::common directly if you need to
# change the version of java, kafka, or scala that is being installed, or if
# you want to install the confluent-kafka package without puppet managing
# a Kafka broker.
#
# == Parameters
#
# [*java_home*]
#   Path to JAVA_HOME.  This class does not manage installation of Java.
#   You must do that elsewhere.  Default: undef (will use system default).
#
# [*distrubution*]
#   The Confluent Kafka distribution version to use.
#   Defaults to '44' (Kafka 1.1)
#
class confluent::kafka::common(
    Optional[String] $java_home = undef,
    Optional[Confluent::Distribution] $distribution = '44',
    $user_group_id = undef,
) {
    $package_44 = 'confluent-kafka-2.11'
    $package_75 = 'confluent-kafka'

    # Kafka 1.1 version is shipped with Confluent 4.4
    # Kafka 3.5 version is shipped with Confluent 7.5
    # We currently support only two versions available to install,
    # and we absent/ensure them accordingly to smooth upgrade/rollback operations.
    # Note: we force the package removal with ensure_resource since the two confluent
    # variants (confluent-kafka and confluent-kafka-2.11) share some common files,
    # so if puppet installs confluent-kafka (Kafka 3.5) before confluent-kafka-2.11
    # (Kafka 1.1) is removed, the Debian package manager will error out causing
    # a Puppet run failure. We will hopefully not have this problem in the future
    # when the supported version to upgrade to/from will have the same package name.
    if $distribution == '44'{
        $ensure_package_44 = true
        $ensure_package_75 = false
        $package = $package_44
        ensure_resource('package', 'confluent-kafka', {'ensure' => 'absent'})
    } elsif $distribution == '75' {
        $ensure_package_44 = false
        $ensure_package_75 = true
        $package = $package_75
        ensure_resource('package', 'confluent-kafka-2.11', {'ensure' => 'absent'})
    } else {
        fail('Kafka distribution not supported.')
    }

    apt::package_from_component { 'confluent-kafka':
        component       => 'thirdparty/confluent',
        packages        => [$package_44],
        ensure_packages => $ensure_package_44,
    }

    apt::package_from_component { 'confluent-kafka-75':
        component       => 'thirdparty/confluent75',
        packages        => [$package_75],
        ensure_packages => $ensure_package_75,
    }

    # Ensure that the confluent systemd units are disabled.  The confluent-kafka
    # package installs these, and we don't want to remove their .service files
    # in case it would cause package conflicts during future upgrades, so we just
    # ensure they are not running and masked in systemd.
    #
    # work around "Error: Could not set 'mask' on enable:undefined method `mask' for Service"
    # that occurs on Jessie hosts by forcing provider => 'systemd'
    service { ['confluent-kafka', 'confluent-kafka-connect', 'confluent-zookeeper']:
        ensure   => 'stopped',
        enable   => 'mask',
        provider => 'systemd',
        require  => Package[$package],
    }

    group { 'kafka':
        ensure  => 'present',
        gid     => $user_group_id,
        system  => true,
        require => Package[$package],
    }
    # Kafka system user
    user { 'kafka':
        gid        => 'kafka',
        uid        => $user_group_id,
        shell      => '/bin/false',
        home       => '/nonexistent',
        comment    => 'Apache Kafka',
        system     => true,
        managehome => false,
        require    => Group['kafka'],
    }

    file { '/var/log/kafka':
        ensure => 'directory',
        owner  => 'kafka',
        group  => 'kafka',
        mode   => '0755',
    }

    file { '/usr/local/bin/kafka':
        source  => 'puppet:///modules/confluent/kafka/kafka.sh',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Package[$package],
    }

    # Have puppet manage totally manage this directory.
    # Anything it doesn't know about will be removed.
    file { '/etc/kafka/mirror':
        ensure  => 'directory',
        owner   => 'kafka',
        group   => 'kafka',
        recurse => true,
        purge   => true,
        force   => true,
        require => Package[$package],
    }
}
