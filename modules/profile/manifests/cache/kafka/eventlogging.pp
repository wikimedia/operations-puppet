# SPDX-License-Identifier: Apache-2.0
# === Class profile::cache::kafka::eventlogging
#
# Sets up a varnishkafka logging endpoint for collecting
# analytics events coming from external clients.
#
# More info: https://wikitech.wikimedia.org/wiki/Analytics/EventLogging
#
# === Parameters
#
# [*kafka_cluster_name*]
#   Name of the Kafka cluster in the kafka_clusters hash to be passed to the
#   kafka_config() function.
#
# [*ssl_enabled*]
#   If true, the Kafka cluster needs to be configured with SSL support.
#   profile::cache::kafka::certificate will be included, and certs used from it.
#   Default: false
#
# [*monitoring_enabled*]
#   True if the varnishkafka instance should be monitored.  Default: false
#
class profile::cache::kafka::eventlogging(
    Wmflib::Ensure $ensure = lookup('profile::cache::kafka::eventlogging::ensure', {'default_value' => 'present'}),
    String $kafka_cluster_name = lookup('profile::cache::kafka::eventlogging::kafka_cluster_name'),
    Boolean $ssl_enabled = lookup('profile::cache::kafka::eventlogging::ssl_enabled', {'default_value' => false}),
    Boolean $monitoring_enabled = lookup('profile::cache::kafka::eventlogging::monitoring_enabled', {'default_value' => false}),
) {
    $kafka_config = kafka_config($kafka_cluster_name)

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


    # Sometimes we get junk data sent from bunk user agents.
    # Any user agent regex patterns we want to exclude from eventlogging data can be put in this
    # list, and varnishkafka will be configured not to send this data.
    # See: https://phabricator.wikimedia.org/T266130
    $user_agent_exclude_pattern = '^Fuzz Faster U Fool'

    varnishkafka::instance { 'eventlogging':
        ensure                      => $ensure,
        brokers                     => $kafka_brokers,
        # Note that this format uses literal tab characters.
        format                      => '%q	%l	%n	%{%FT%T}t	%{X-Client-IP}o	"%{User-agent}i"',
        format_type                 => 'string',
        compression_codec           => 'snappy',
        topic                       => 'eventlogging-client-side',
        varnish_name                => 'frontend',
        varnish_svc_name            => 'varnish-frontend',
        # Only listen and log requests to /beacon/event(.gif)? that are not from user agents we want to exclude.
        varnish_opts                => { 'q' => "ReqURL ~ \"^/(beacon/)?event(\\.gif)?\\?\" and ReqHeader:user-agent !~ \"${user_agent_exclude_pattern}\"" },
        topic_request_required_acks => '1',
        #TLS/SSL config
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

    if $monitoring_enabled {
        # Aggregated alarms for delivery errors are defined in icinga::monitor::analytics

        # Generate icinga alert if varnishkafka is not running.
        nrpe::monitor_service { 'varnishkafka-eventlogging':
            ensure        => $ensure,
            description   => 'eventlogging Varnishkafka log producer',
            nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1:1 -a '/usr/bin/varnishkafka -S /etc/varnishkafka/eventlogging.conf'",
            contact_group => 'admins,analytics,team-data-platform',
            require       => Varnishkafka::Instance['eventlogging'],
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Varnishkafka',
        }
    }

    # Make sure varnishes are configured and started for the first time
    # before the instances as well, or they fail to start initially...
    Service <| tag == 'varnish_instance' |> -> Varnishkafka::Instance['eventlogging']
}
