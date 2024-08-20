# SPDX-License-Identifier: Apache-2.0
# === Class profile::cache::kafka::statsv
#
# Sets up a varnishkafka logging endpoint for collecting
# application level metrics. We are calling this system
# statsv, as it is similar to statsd, but uses varnish
# as its logging endpoint.
#
# === Parameters
#
# [*kafka_cluster_name*]
#   The name of the kafka cluster to use from the kafka_clusters hiera variable.
#   Since only one statsd instance is active at any given time, you should probably
#   set this explicitly to a fully qualified kafka cluster name (with DC suffix) that
#   is located in the same DC as the active statsd instance.
#
# [*monitoring_enabled*]
#   True if the varnishkafka instance should be monitored.  Default: false
#
class profile::cache::kafka::statsv(
    String $kafka_cluster_name  = lookup('profile::cache::kafka::statsv::kafka_cluster_name'),
    Boolean $monitoring_enabled = lookup('profile::cache::kafka::statsv::monitoring_enabled', {default_value => false}),
    Boolean $ssl_enabled        = lookup('profile::cache::kafka::statsv::ssl_enabled', {'default_value' => false}),
)
{
    $kafka_config  = kafka_config($kafka_cluster_name)

    if $ssl_enabled {
        $kafka_brokers = $kafka_config['brokers']['ssl_array']

        include profile::cache::kafka::certificate

        # Include this class to get key and certificate for varnishkafka
        # to produce to Kafka over SSL/TLS.
        $ssl_ca_location = $profile::cache::kafka::certificate::ssl_ca_location
        $ssl_cipher_suites = $profile::cache::kafka::certificate::ssl_cipher_suites
        $ssl_curves_list = $profile::cache::kafka::certificate::ssl_curves_list
        $ssl_sigalgs_list = $profile::cache::kafka::certificate::ssl_sigalgs_list
        $ssl_keystore_password = $profile::cache::kafka::certificate::ssl_key_password
        $ssl_key_password = $profile::cache::kafka::certificate::ssl_key_password
        $ssl_key_location = $profile::cache::kafka::certificate::ssl_key_location
        $ssl_certificate_location = $profile::cache::kafka::certificate::ssl_certificate_location
    }
    else {
        $kafka_brokers = $kafka_config['brokers']['array']

        $ssl_ca_location = undef
        $ssl_key_password = undef
        $ssl_key_location = undef
        $ssl_certificate_location = undef
        $ssl_cipher_suites = undef
        $ssl_curves_list = undef
        $ssl_sigalgs_list = undef
        $ssl_keystore_password = undef
    }

    $format  = "%{fake_tag0@hostname?${::fqdn}}x %{%FT%T@dt}t %{X-Client-IP@ip}o %{@uri_path}U %{@uri_query}q %{User-Agent@user_agent}i"

    varnishkafka::instance { 'statsv':
        brokers                     => $kafka_brokers,
        format                      => $format,
        format_type                 => 'json',
        topic                       => 'statsv',
        varnish_name                => 'frontend',
        varnish_svc_name            => 'varnish-frontend',
        # Only log webrequests to /beacon/statsv
        varnish_opts                => { 'q' => 'ReqURL ~ "^/beacon/statsv\?"' },
        # -1 means all brokers in the ISR must ACK this request.
        topic_request_required_acks => '-1',
        # TLS/SSL config
        ssl_enabled                 => $ssl_enabled,
        ssl_ca_location             => $ssl_ca_location,
        ssl_key_password            => $ssl_key_password,
        ssl_key_location            => $ssl_key_location,
        ssl_certificate_location    => $ssl_certificate_location,
        ssl_cipher_suites           => $ssl_cipher_suites,
        ssl_curves_list             => $ssl_curves_list,
        ssl_sigalgs_list            => $ssl_sigalgs_list,
        ssl_keystore_location       => undef,
        ssl_keystore_password       => $ssl_keystore_password,
    }

    # Make sure varnishes are configured and started for the first time
    # before the instances as well, or they fail to start initially...
    Service <| tag == 'varnish_instance' |> -> Varnishkafka::Instance['statsv']

    if $monitoring_enabled {
        # Aggregated alarms for delivery errors are defined in icinga::monitor::analytics

        # Generate icinga alert if varnishkafka is not running.
        nrpe::monitor_service { 'varnishkafka-statsv':
            description   => 'statsv Varnishkafka log producer',
            nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1:1 -a '/usr/bin/varnishkafka -S /etc/varnishkafka/statsv.conf'",
            contact_group => 'admins,analytics,team-data-platform',
            require       => Class['::varnishkafka'],
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Varnishkafka',
        }
    }
}
