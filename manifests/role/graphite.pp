# == Class: role::graphite::base
# Base class for setting up a graphite instance.
#
# Sets up graphite + carbon listeners, with 8 carbon listeners running on localhost
# feeding data into graphite.
# Also sets up basic icinga checks.
#
# === Parameters
#
# [*storage_dir*]
#
#   Location to store the whisper files used by graphite in
#
# [*auth*]
#
#   Set to true to enable LDAP based authentication to access the graphite interface
#
class role::graphite::base(
    $storage_dir      = '/var/lib/carbon',
    $auth             = true,
    $hostname         = 'graphite.wikimedia.org',
    $c_relay_settings = {},
) {
    include ::passwords::graphite

    if $::realm == 'labs' {
        # Mount extra disk on /srv so carbon has somewhere to store metrics
        require role::labs::lvm::srv
    }

    system::role { 'role::graphite':
        description => 'real-time metrics processor',
    }

    $carbon_storage_dir = $storage_dir

    class { '::graphite':
        # First match wins with storage schemas
        storage_schemas     => {
            # Retain daily metrics for 25 years
            'daily' => {
                pattern    => '^daily\..*',
                retentions => '1d:25y',
            },
            # Retain aggregated data at a one-minute resolution for one week; at
            # five-minute resolution for two weeks; at 15-minute resolution for
            # one month; and at one-hour resolution for one year.
            'default' => {
                pattern    => '.*',
                retentions => '1m:7d,5m:14d,15m:30d,1h:1y',
            },
        },

        # Aggregation methods for whisper files.
        storage_aggregation => {
            'min'   => {
                pattern           => '\.min$',
                xFilesFactor      => 0.01,
                aggregationMethod => 'min',
            },
            'max'   => {
                pattern           => '\.max$',
                xFilesFactor      => 0.01,
                aggregationMethod => 'max',
            },
            'count'   => {
                pattern           => '\.count$',
                xFilesFactor      => 0.01,
                aggregationMethod => 'sum',
            },
            'sum'   => {
                pattern           => '\.sum$',
                xFilesFactor      => 0.01,
                aggregationMethod => 'sum',
            },
            # statsite extended counters
            'lower' => {
                pattern           => '\.lower$',
                xFilesFactor      => 0.01,
                aggregationMethod => 'min',
            },
            'upper' => {
                pattern           => '\.upper$',
                xFilesFactor      => 0.01,
                aggregationMethod => 'max',
            },
            'default' => {
                pattern           => '.*',
                xFilesFactor      => 0.01,
            },
        },

        # All metric data goes through a single carbon-relay instance, which
        # forwards each data point to one of eight carbon-cache instances, using
        # a consistent hash ring to distribute the load.
        #
        # Why is this necessary? Because carbon-cache is CPU-bound, and the Python
        # GIL prevents it from utilizing multiple processor cores efficiently.
        #
        # cf. "Single node, multiple carbon-caches"
        # <http://bitprophet.org/blog/2013/03/07/graphite/>
        #
        # If we need to scale up, the next step is multi-node.
        # <http://tinyurl.com/graphite-cluster-setup>.
        carbon_settings     => {
            'cache'   => {
                line_receiver_interface            => '127.0.0.1',  # Only the relay binds to 0.0.0.0.
                pickle_receiver_interface          => '127.0.0.1',
                max_cache_size                     => 'inf',
                max_creates_per_minute             => '100',
                max_updates_per_second_on_shutdown => '1000',
            },

            ## Carbon caches ##

            'cache:a' => {
                line_receiver_port   => 2103,
                pickle_receiver_port => 2104,
                cache_query_port     => 7102,
            },
            'cache:b' => {
                line_receiver_port   => 2203,
                pickle_receiver_port => 2204,
                cache_query_port     => 7202,
            },
            'cache:c' => {
                line_receiver_port   => 2303,
                pickle_receiver_port => 2304,
                cache_query_port     => 7302,
            },
            'cache:d' => {
                line_receiver_port   => 2403,
                pickle_receiver_port => 2404,
                cache_query_port     => 7402,
            },
            'cache:e' => {
                line_receiver_port   => 2503,
                pickle_receiver_port => 2504,
                cache_query_port     => 7502,
            },
            'cache:f' => {
                line_receiver_port   => 2603,
                pickle_receiver_port => 2604,
                cache_query_port     => 7602,
            },
            'cache:g' => {
                line_receiver_port   => 2703,
                pickle_receiver_port => 2704,
                cache_query_port     => 7702,
            },
            'cache:h' => {
                line_receiver_port   => 2803,
                pickle_receiver_port => 2804,
                cache_query_port     => 7802,
            },

            ## Carbon relay ##

            'relay'   => {
                pickle_receiver_interface => '0.0.0.0',
                # disabled, see ::graphite::carbon_c_relay
                line_receiver_port        => '0',
                relay_method              => 'consistent-hashing',
                max_queue_size            => '500000',
                destinations              => [
                    '127.0.0.1:2104:a',
                    '127.0.0.1:2204:b',
                    '127.0.0.1:2304:c',
                    '127.0.0.1:2404:d',
                    '127.0.0.1:2504:e',
                    '127.0.0.1:2604:f',
                    '127.0.0.1:2704:g',
                    '127.0.0.1:2804:h',
                ],
            },
        },

        storage_dir         => $carbon_storage_dir,
        whisper_lock_writes => true,
        c_relay_settings    => $c_relay_settings,
    }

    class { '::graphite::web':
        admin_user        => $::passwords::graphite::user,
        admin_pass        => $::passwords::graphite::pass,
        remote_user_auth  => true,
        secret_key        => $::passwords::graphite::secret_key,
        storage_dir       => $carbon_storage_dir,
        documentation_url => '//wikitech.wikimedia.org/wiki/Graphite',
        cors_origins      => [ 'https?://(grafana|grafana-admin).wikimedia.org' ],
    }


    include ::apache
    include ::apache::mod::uwsgi

    if $auth {
        # Production
        include ::passwords::ldap::production
        include ::apache::mod::authnz_ldap

        $ldap_authurl  = 'ldaps://ldap-labs.eqiad.wikimedia.org ldap-labs.codfw.wikimedia.org/ou=people,dc=wikimedia,dc=org?cn'
        $ldap_bindpass = $passwords::ldap::production::proxypass
        $ldap_binddn   = 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org'
        $ldap_groups   = [
            'cn=ops,ou=groups,dc=wikimedia,dc=org',
            'cn=nda,ou=groups,dc=wikimedia,dc=org',
            'cn=wmf,ou=groups,dc=wikimedia,dc=org'
        ]
        $auth_realm    = 'WMF Labs (use wiki login name not shell) - nda/ops/wmf'
        $apache_auth   = template('graphite/apache-auth-ldap.erb')
    }

    apache::site { $hostname:
        content => template('graphite/graphite.apache.erb'),
    }

    nrpe::monitor_service { 'carbon':
        description  => 'Graphite Carbon',
        nrpe_command => '/sbin/carbonctl check',
    }

    # This check goes to the backend, which is http.
    monitoring::service { 'graphite':
        description   => 'graphite.wikimedia.org',
        check_command => 'check_http_url!graphite.wikimedia.org!/render',
    }
}

# == Class: role::graphite::production
#
# Set up graphite instance for production.
# Also includes icinga checks for anomalies for Mediawiki, EL & Swift metrics
# Instance requires people to authenticate via LDAP before they can see metrics.
#
class role::graphite::production {
    class { 'role::graphite::base':
        storage_dir      => '/var/lib/carbon',
        auth             => true,
        c_relay_settings => {
          backends => [
            'graphite1001.eqiad.wmnet:1903',
            'graphite2001.codfw.wmnet:1903',
          ],
        }
    }
}

# == Class: role::graphite::alerts
#
# Install icinga alerts on graphite metrics.
# NOTE to be included only from one host, icinga will generate different alerts
# for all hosts that include this class.
#
class role::graphite::alerts {
    # Infer Kafka cluster configuration from this class
    include ::role::analytics::kafka::config

    include ::mediawiki::monitoring::graphite
    include ::graphite::monitoring::graphite

    # Alerts for EventLogging metrics in Kafka.
    class { '::eventlogging::monitoring::graphite':
        kafka_brokers_graphite_wildcard =>  $::role::analytics::kafka::config::brokers_graphite_wildcard
    }

    swift::monitoring::graphite_alerts { 'eqiad-prod': }
    swift::monitoring::graphite_alerts { 'codfw-prod': }

    # Use graphite's anomaly detection support.
    monitoring::graphite_anomaly { 'kafka-broker-MessagesIn-anomaly':
        description  => 'Kafka Broker Messages In Per Second',
        metric       => 'sumSeries(kafka.*.kafka.server.BrokerTopicMetrics-AllTopics.MessagesInPerSec.OneMinuteRate)',
        # check over the 60 data points (an hour?) and:
        # - alert warn if more than 30 are under the confidence band
        # - alert critical if more than 45 are under the confidecne band
        check_window => 60,
        warning      => 30,
        critical     => 45,
        under        => true,
        group        => 'analytics_eqiad',
    }

    # Monitor memcached error rate from MediaWiki. This is commonly a sign of
    # a failing nutcracker instance that can be tracked down via
    # https://logstash.wikimedia.org/#/dashboard/elasticsearch/memcached
    monitoring::graphite_threshold { 'mediawiki-memcached-threshold':
        description => 'MediaWiki memcached error rate',
        metric      => 'logstash.rate.mediawiki.memcached.ERROR.sum',
        # Nominal error rate in production is <150/min
        warning     => 1000,
        critical    => 5000,
        from        => '5min',
        percentage  => 40,
    }

}

class role::graphite::alerts::reqstats {

    # Global threshold alarm as we had with reqstats.5xx
    # Monitor production 5xx rates
    monitoring::graphite_threshold { 'reqstats-5xx-global':
        description     => 'HTTP 5xx reqs/min (https://grafana.wikimedia.org/dashboard/db/varnish-http-errors)',
        metric          => 'sumSeries(varnish.*.*.frontend.request.client.status.5xx.sum)',
        warning         => 250,
        critical        => 500,
        from            => '15min',
        nagios_critical => false,
    }

    # sites aggregates
    monitoring::graphite_threshold { 'reqstats-5xx-eqiad':
        description     => 'Eqiad HTTP 5xx reqs/min',
        metric          => 'sumSeries(varnish.eqiad.*.frontend.request.client.status.5xx.sum)',
        warning         => 75,
        critical        => 150,
        from            => '15min',
        nagios_critical => false,
    }

    monitoring::graphite_threshold { 'reqstats-5xx-esams':
        description     => 'Esams HTTP 5xx reqs/min',
        metric          => 'sumSeries(varnish.esams.*.frontend.request.client.status.5xx.sum)',
        warning         => 75,
        critical        => 150,
        from            => '15min',
        nagios_critical => false,
    }

    monitoring::graphite_threshold { 'reqstats-5xx-codfw':
        description     => 'Codfw HTTP 5xx reqs/min',
        metric          => 'sumSeries(varnish.codfw.*.frontend.request.client.status.5xx.sum)',
        warning         => 75,
        critical        => 150,
        from            => '15min',
        nagios_critical => false,
    }

    monitoring::graphite_threshold { 'reqstats-5xx-ulsfo':
        description     => 'Ulsfo HTTP 5xx reqs/min',
        metric          => 'sumSeries(varnish.ulsfo.*.frontend.request.client.status.5xx.sum)',
        warning         => 75,
        critical        => 150,
        from            => '15min',
        nagios_critical => false,
    }

    # per-cache aggregates
    monitoring::graphite_threshold { 'reqstats-5xx-text':
        description     => 'Text HTTP 5xx reqs/min',
        metric          => 'sumSeries(varnish.*.text.frontend.request.client.status.5xx.sum)',
        warning         => 75,
        critical        => 150,
        from            => '15min',
        nagios_critical => false,
    }

    monitoring::graphite_threshold { 'reqstats-5xx-mobile':
        description     => 'Mobile HTTP 5xx reqs/min',
        metric          => 'sumSeries(varnish.*.mobile.frontend.request.client.status.5xx.sum)',
        warning         => 75,
        critical        => 150,
        from            => '15min',
        nagios_critical => false,
    }

    monitoring::graphite_threshold { 'reqstats-5xx-uploads':
        description     => 'Uploads HTTP 5xx reqs/min',
        metric          => 'sumSeries(varnish.*.uploads.frontend.request.client.status.5xx.sum)',
        warning         => 75,
        critical        => 150,
        from            => '15min',
        nagios_critical => false,
    }

    monitoring::graphite_threshold { 'reqstats-5xx-misc':
        description     => 'Misc HTTP 5xx reqs/min',
        metric          => 'sumSeries(varnish.*.misc.frontend.request.client.status.5xx.sum)',
        warning         => 75,
        critical        => 150,
        from            => '15min',
        nagios_critical => false,
    }

    monitoring::graphite_threshold { 'reqstats-5xx-parsoid':
        description     => 'Parsoid HTTP 5xx reqs/min',
        metric          => 'sumSeries(varnish.*.parsoid.frontend.request.client.status.5xx.sum)',
        warning         => 75,
        critical        => 150,
        from            => '15min',
        nagios_critical => false,
    }

    monitoring::graphite_threshold { 'reqstats-5xx-maps':
        description     => 'Maps HTTP 5xx reqs/min',
        metric          => 'sumSeries(varnish.*.maps.frontend.request.client.status.5xx.sum)',
        warning         => 75,
        critical        => 150,
        from            => '15min',
        nagios_critical => false,
    }
}
