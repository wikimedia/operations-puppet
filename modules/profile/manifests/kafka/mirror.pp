# == Class profile::kafka::mirror
# Sets up an individual MirrorMaker instance to mirror from $source_cluster_name
# to $destination_cluster_name.  Consumer and Producer properties will automatically
# include proper max message bytes / batch size settings.  Any other MirrorMaker
# Consumer or Producer properties you need to set should be provided in $properties,
# with keys that match the confluent::kafka::mirror::instance define parameters.
#
# == SSL Configuration
#
# To configure SSL for Kafka MirrorMaker, you need the following files distributable by our Puppet
# secret() function.
#
# - A keystore.jks file   - Contains the key and certificate for the Kafka clients
# - A truststore.jks file - Contains the CA certificate that signed the Kafka client certificate
#
# It is expected that the CA certificate in the truststore will also be used to sign
# all Kafka client certificates.  These should be checked into the Puppet private repository's
# secret module at
#
#   - secrets/certificates/kafka_mirror_maker/kafka_mirror_maker.keystore.jks
#   - secrets/certificates/kafka_mirror_maker/truststore.jks
#
# The same certificate will be used for all Kafka MirrorMaker instances.  The expected
# DN is CN=kafka_mirror_maker.
#
# This layout is built to work with certificates generated using cergen like
#    cergen --base-path /srv/private/modules/secret/secrets/certificates ...
#
# Once these are in the Puppet private repository's secret module, set
# $consumer_ssl_enabled and/or $producer_ssl_enabled to true and  $ssl_password to the password
# used when genrating the key, keystore, and truststore.
#
# See https://wikitech.wikimedia.org/wiki/Cergen for more details.
#
# When you enable SSL for MirrorMaker, User:CN=kafka_mirror_maker should be granted
# consumer and/or producer privileges via ACLs.  This will not be done for you.
# Run the following command to add them.
#
#  kafka acls --add --allow-principal User:CN=kafka_mirror_maker --topic '*' --group '*' --producer --consumer
#
# == Parameters
#
# [*enabled*]
#   If false, kafka mirror-maker service will not be started.  Default: true.
#
# [*source_cluster_name*]
#   This will be passed to the kafka_config function to find the source cluster brokers.
#
# [*destination_cluster_name*]
#   This will be passed to the kafka_config function to find the destination cluster brokers.
#
# [*properties*]
#   Hash of extra properties to pass to confluent::kafka::mirror::instance.
#   Default: {}
#
# [*num_processes*]
#   Number of (systemd based) processes to spawn for this MirrorMaker.  Default: 1
#
# [*consumer_ssl_enabled*]
#   If true, an SSL will be used to consume from the source cluster. Default: false
#
# [*producer_ssl_enabled*]
#   If true, an SSL will be used to produce to the destination cluster  Default: false
#
# [*ssl_password*]
#   Password for keystores and keys.  You should
#   set this in hiera in the operations puppet private repository.
#   Hiera: profile::kafka::mirror::ssl_password  This expects
#   that all keystore, truststores, and keys use the same password.
#   Default: undef
#
# [*monitoring_enabled*]
#   If true, monitoring (via prometheus) will be enabled for this MirrorMaker instance.
#
# [*jmx_base_port*]
#   Starting port for JMX.  Each instantiated process will +1 to this port.
#   Default: 9900
#
# [*jmx_exporter_base_port*]
#   Starting port for Prometheus JMX exporter.  Each instantiated process will +1 to this port.
#   Only used if $monitoring_enabled is true.  Default: 7900
#
# [*message_max_bytes*]
#   Max Kafka message size.  Should be synchronized between all producers, brokers, and consumers.
#
# [*prometheus_nodes*]
#   Prometheus nodes that should be allowed to query the JMX exporter.
#
class profile::kafka::mirror(
    $enabled                  = hiera('profile::kafka::mirror::enabled', true),
    $source_cluster_name      = hiera('profile::kafka::mirror::source_cluster_name'),
    $destination_cluster_name = hiera('profile::kafka::mirror::destination_cluster_name'),
    $properties               = hiera('profile::kafka::mirror::properties', {}),
    $num_processes            = hiera('profile::kafka::mirror::num_processes', 1),
    $consumer_ssl_enabled     = hiera('profile::kafka::mirror::consumer_ssl_enabled', false),
    $producer_ssl_enabled     = hiera('profile::kafka::mirror::producer_ssl_enabled', false),
    $ssl_password             = hiera('profile::kafka::mirror::ssl_password', undef),
    $monitoring_enabled       = hiera('profile::kafka::mirror::monitoring_enabled', true),
    $jmx_base_port            = hiera('profile::kafka:mirror:jmx_base_port', 9900),
    $jmx_exporter_base_port   = hiera('profile::kafka::mirror:jmx_exporter_base_port', 7900),
    $message_max_bytes        = hiera('kafka_message_max_bytes'),
    $prometheus_nodes         = hiera('prometheus_nodes'),
) {
    $source_config            = kafka_config($source_cluster_name)
    $destination_config       = kafka_config($destination_cluster_name)

    # This is the name of the logical MirrorMaker instance.  It will be used
    # for the consumer group.id.  Each individual process belonging to this will
    # be named $mirror_instance_name@$process_num.
    $mirror_instance_name = "${source_config['name']}_to_${destination_config['name']}"


    # All MirrorMaker instances use the same certificate.
    $certificate_name = 'kafka_mirror_maker'
    $ssl_location     = '/etc/kafka/mirror/ssl'

    # Consumer and Producer use the same SSL properties.
    if $consumer_ssl_enabled or $producer_ssl_enabled {
        $ssl_keystore_secrets_path      = "certificates/${certificate_name}/${certificate_name}.keystore.jks"
        $ssl_keystore_location          = "${ssl_location}/${certificate_name}.keystore.jks"

        $ssl_truststore_secrets_path    = "certificates/${certificate_name}/truststore.jks"
        $ssl_truststore_location        = "${ssl_location}/truststore.jks"

        # https://phabricator.wikimedia.org/T182993#4208208
        $ssl_java_opts                  = '-Djdk.tls.namedGroups=secp256r1 '

        if !defined(File[$ssl_location]) {
            file { $ssl_location:
                ensure  => 'directory',
                owner   => 'kafka',
                group   => 'kafka',
                mode    => '0555',
                # Install certificates after confluent-kafka package has been
                # installed and /etc/kafka already exists.
                require => Class['::confluent::kafka::common'],
            }
        }
        file { $ssl_keystore_location:
            content => secret($ssl_keystore_secrets_path),
            owner   => 'kafka',
            group   => 'kafka',
            mode    => '0440',
        }
        File[$ssl_keystore_location] -> Confluent::Kafka::Mirror::Instance <| |>


        if !defined(File[$ssl_truststore_location]) {
            file { $ssl_truststore_location:
                content => secret($ssl_truststore_secrets_path),
                owner   => 'kafka',
                group   => 'kafka',
                mode    => '0444',
            }
        }
        File[$ssl_truststore_location] -> Confluent::Kafka::Mirror::Instance <| |>


        # These will be used for consumer and/or producer properties.
        $ssl_properties = {
            'security.protocol'       => 'SSL',
            'ssl.truststore.location' => $ssl_truststore_location,
            'ssl.truststore.password' => $ssl_password,
            'ssl.keystore.location'   => $ssl_keystore_location,
            'ssl.keystore.password'   => $ssl_password,
            'ssl.key.password'        => $ssl_password,
            'ssl.enabled.protocols'   => 'TLSv1.2',
            'ssl.cipher.suites'       => 'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384',
        }
    }
    else {
        $ssl_properties = {}
        $ssl_java_opts  = ''
    }

    if $consumer_ssl_enabled {
        $consumer_ssl_properties = $ssl_properties
        $source_brokers          = split($source_config['brokers']['ssl_string'], ',')
    }
    else {
        $consumer_ssl_properties = {}
        $source_brokers          = split($source_config['brokers']['string'], ',')
    }

    if $producer_ssl_enabled {
        $producer_ssl_properties = $ssl_properties
        $destination_brokers     = split($destination_config['brokers']['ssl_string'], ',')
    }
    else {
        $producer_ssl_properties = {}
        $destination_brokers     = split($destination_config['brokers']['string'], ',')
    }

    # The requests not only contain the message but also a small metadata overhead.
    # So if we want to produce a kafka_message_max_bytes payload the max request size should be
    # a bit higher.  In Kafka 0.11+, there is a bit more metadata, and I've seen a request
    # of size 5272680 even though max.message.bytes is 4Mb.  Increase request size + 1.5 MB.
    $producer_request_max_size = $message_max_bytes + 1572864

    # Merge other consumer and producer properties together with the ssl configuration.
    $consumer_properties = merge(
        {
            # RoundRobin results in more balanced consumer assignment when dealing
            # with many single partition topics.
            'partition.assignment.strategy' => 'org.apache.kafka.clients.consumer.RoundRobinAssignor',
            'max.partition.fetch.bytes'     => $producer_request_max_size
        },
        $consumer_ssl_properties
    )

    $producer_properties = merge(
        {
            'max.request.size' => $producer_request_max_size
        },
        $producer_ssl_properties
    )

    # Iterate and instantiate $num_processes MirrorMaker processes using these configs.
    range(0, $num_processes - 1).each |$process| {

        # Use the names from the config hashes, rather than as passed in, since names passed in
        # might not be fully suffixed with datacenter name.
        $mirror_process_name = "${mirror_instance_name}@${process}"

        if $monitoring_enabled {
            $prometheus_jmx_exporter_port = $jmx_exporter_base_port + $process
            $jmx_exporter_config_file = "/etc/kafka/mirror/${mirror_process_name}/prometheus_jmx_exporter.yaml"

            # Use this in your JAVA_OPTS you pass to the Kafka MirrorMaker process
            $prometheus_java_opts = "-javaagent:/usr/share/java/prometheus/jmx_prometheus_javaagent.jar=${::ipaddress}:${prometheus_jmx_exporter_port}:${jmx_exporter_config_file}"

            # Declare a prometheus jmx_exporter instance.
            # This will render the config file, declare the jmx_exporter_instance,
            # and configure ferm.
            profile::prometheus::jmx_exporter { "kafka_mirror_${$mirror_process_name}_${::hostname}":
                hostname         => $::hostname,
                port             => $prometheus_jmx_exporter_port,
                prometheus_nodes => $prometheus_nodes,
                config_file      => $jmx_exporter_config_file,
                content          => template('profile/kafka/mirror_maker_prometheus_jmx_exporter.yaml.erb'),
                labels           => {
                    'mirror_name' => $mirror_instance_name,
                },
            }

            # Generate icinga alert if MirrorMaker process is not running.
            nrpe::monitor_service { "kafka-mirror-${mirror_process_name}":
                description  => "Kafka MirrorMaker ${mirror_process_name}",
                nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 -C java  --ereg-argument-array 'kafka.tools.MirrorMaker.+/etc/kafka/mirror/${mirror_process_name}/producer\\.properties'",
                require      => Confluent::Kafka::Mirror::Instance[$mirror_process_name],
                notes_url    => 'https://wikitech.wikimedia.org/wiki/Kafka/Administration#MirrorMaker',
            }

            # More alerts can be added by declaring
            # profile::kafka::mirror::alerts { $mirror_process_name: }
            # elsewhere, usually in profile::prometheus::alerts.
        }
        else {
            $prometheus_java_opts = ''
        }

        # Minimum defaults for configuring a MirrorMaker instance.
        $default_parameters = {
            'enabled'             => $enabled,
            'source_brokers'      => $source_brokers,
            'destination_brokers' => $destination_brokers,
            'producer_properties' => $producer_properties,
            'consumer_properties' => $consumer_properties,
            'java_opts'           => "${ssl_java_opts}${prometheus_java_opts}",
            'jmx_port'            => $jmx_base_port + $process,
            'group_id'            => "kafka-mirror-${mirror_instance_name}",
        }

        # This hash will be passed to confluent::kafka::mirror::instance.
        # Use deep_merge because producer and consumer properties are also hashes.
        $mirror_parameters = deep_merge(
            $default_parameters,
            $properties
        )

        # Create the mirror instance using create_resources.  This allows us to pass parameters
        # from hiera, with some sane defaults, to the mirror::instance without declaring
        # every possible mirror::instance parameter here.  Any that aren't defined in $mirror_parameters
        # will just use the confluent::kafka::mirror::instance defaults.
        # If we didn't do this, we'd have to add around 8 more paramters to this profile
        # now, and possibly more as needed later.
        create_resources(
            'confluent::kafka::mirror::instance',
            { "${mirror_process_name}" => $mirror_parameters }
        )
    }
}
