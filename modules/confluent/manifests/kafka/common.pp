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
#   Defaults to '77' (Kafka 3.7)
#
# [*super_user_client_credentials_path*]
#   If super.users are set and TLS is used, instruct the kafka client
#   wrapper script to use their credentials when issuing commands.
#   Defaults to false.
#
class confluent::kafka::common(
    Optional[String] $java_home = undef,
    Optional[Confluent::Distribution] $distribution = '77',
    $user_group_id = undef,
    Optional[Stdlib::Unixpath] $super_user_client_credentials_path = undef,
) {
    $package_7x = 'confluent-kafka'

    # Kafka 3.7 version is shipped with Confluent 7.7
    # We currently support only two versions available to install,
    if $distribution == '77' {
        $ensure_package_77 = true
        $package = $package_7x
        ensure_resource('package', 'confluent-kafka-2.11', {'ensure' => 'absent'})
    } else {
        fail('Kafka distribution not supported.')
    }

    apt::package_from_component { 'confluent-kafka-77':
        ensure    => $ensure_package_77.bool2str('present', 'absent'),
        component => 'thirdparty/confluent77',
        packages  => [$package_7x],
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

    if $distribution == '77' {
        $kafka_script = 'kafka3.sh'
        $kafka_file_source  = undef
        $kafka_file_content = template("confluent/kafka/${kafka_script}.erb")
    } else {
        fail('Kafka distribution not supported.')
    }

    file { '/usr/local/bin/kafka':
        source  => $kafka_file_source,
        content => $kafka_file_content,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Package[$package],
    }
}
