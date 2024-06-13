# vim:sw=4 ts=4 sts=4 et:

# = Define: logstash::input::kafka
#
# Configure logstash to collect input from a Kafka topic.
#
# If $security_protocol == SSL, this will install the
# Kafka truststore.jks file at /etc/logstash/kafka_$cluster_name.truststore.jks
# from the Puppet private secrets module.  This assumes that the Kafka
# truststore is available via the function
# secret("certificates/kafka_${kafka_cluster_name_full}_broker/truststore.jks").
# This should be the correct path to the cergen created truststore for the
# specified Kafka cluster.
#
# == Parameters:
#
# [*kafka_cluster_name*]
#   Kafka cluster name.  Either non datacenter prefixed cluster name,
#   or the full cluster name key in the kafka_clusters hiera variable.
#
# [*topic*]
#   Kafka topic. Default: $title.
#
# [*topics_pattern*]
#   Kafka topic pattern. Default: None. Supersedes $topic if set.
#
# [*group_id*]
#   Kafka consumer group id. Default: None (use logstash implemented default of "logstash")
#
# [*auto_offset_reset*]
#   What to do when there is no initial offset in Kafka or if an offset is out of range.
#
# [*security_protocol*]
#   Security protocol to use, which can be either of PLAINTEXT,SSL,SASL_PLAINTEXT,SASL_SSL
#   must be set to SSL for ssl_truststore* configs to be set
#   see https://www.elastic.co/guide/en/logstash/current/plugins-inputs-kafka.html#plugins-inputs-kafka-security_protocol
#
# [*ssl_truststore_location*]
#   jks truststore location value. Default: none. Requires $security_protocol = 'SSL'
#
# [*ssl_truststore_password*]
#   jks truststore password value. Default: none. Requires $security_protocol = 'SSL'
#
# [*manage_truststore*]
#   Enables puppet to manage the deployed truststore file. Default: true
#
# [*priority*]
#   Configuration loading priority. Default: '10'.
#
# [*tags*]
#   Array of tags to be added to the logs. Default: [$title].
#
# [*consumer_threads*]
#   number of logstash consumer threads.
#
# [*type*]
#   Log type to be passed to Logstash. Default: none.
#
# [*codec*]
#   Codec to decode input. Default 'plain'.
#
# [*plugin_id*]
#   Name associated with Logstash metrics
#
# [*ensure*]
#   Whether the config should exist. Default: present.
#
# == Sample usage:
#
#   logstash::input::kafka { 'some_topic':
#       kafka_cluster_name => 'logging-eqiad'
#   }
#
define logstash::input::kafka(
    String $kafka_cluster_name,
    String $topic                                                                    = $title,
    Optional[String] $topics_pattern                                                 = undef,
    Optional[String] $group_id                                                       = undef,
    Optional[Enum['earliest', 'latest', 'none']] $auto_offset_reset                  = undef,
    Optional[Enum['PLAINTEXT','SSL','SASL_PLAINTEXT','SASL_SSL']] $security_protocol = undef,
    Optional[String] $ssl_truststore_location                                        = undef,
    Optional[String] $ssl_truststore_password                                        = undef,
    Optional[String] $ssl_endpoint_identification_algorithm                          = undef,
    Boolean $manage_truststore                                                       = true,

    $priority                                                                        = 10,
    $tags                                                                            = [$title],
    Integer $consumer_threads                                                        = 1,
    Optional[String] $type                                                           = undef,
    String $codec                                                                    = 'plain',
    $plugin_id                                                                       = "input/kafka/${title}",
    $ensure                                                                          = present,
) {
    $logstash_conf_title = "input-kafka-${title}"

    $kafka_config = kafka_config($kafka_cluster_name)
    $kafka_cluster_name_full = $kafka_config['name']

    if ($security_protocol == 'SSL') {
        if !$ssl_truststore_password {
            fail('Must provide $ssl_truststore_password if using logstash::input::kafka with $security_protocol=SSL')
        }

        $bootstrap_servers = $kafka_config['brokers']['ssl_string']
        $_ssl_truststore_location = $ssl_truststore_location ? {
            undef   => "/etc/logstash/kafka_${kafka_cluster_name_full}.truststore.jks",
            default => $ssl_truststore_location,
        }

        if $manage_truststore {
            if !defined(File[$_ssl_truststore_location]){
                file { $_ssl_truststore_location:
                    content => secret("certificates/kafka_${kafka_cluster_name_full}_broker/truststore.jks"),
                    owner   => 'logstash',
                    group   => 'logstash',
                    mode    => '0440',
                }
            }
            # If using SSL, the Kafka input logstash conf
            # should depend on File $ssl_truststore_location.
            Logstash::Conf[$logstash_conf_title] { require => File[$_ssl_truststore_location] }
        }
    }
    else {
        $bootstrap_servers = $kafka_config['brokers']['string']
    }

    logstash::conf { $logstash_conf_title:
        ensure   => $ensure,
        content  => template('logstash/input/kafka.erb'),
        priority => $priority,
    }
}
