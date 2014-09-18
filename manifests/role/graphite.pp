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
    $storage_dir = '/var/lib/carbon',
    $auth = true,
    $hostname = 'graphite.wikimedia.org',
) {
    include ::passwords::graphite

    if ($::realm == 'labs') {
        # Mount extra disk on /srv so carbon has somewhere to store metrics
        require role::labs::lvm::srv
    }

    system::role { 'role::graphite':
        description => 'real-time metrics processor',
    }

    $carbon_storage_dir = $storage_dir

    class { '::graphite':
        storage_schemas     => {
            # Retain aggregated data at a one-minute resolution for one week; at
            # five-minute resolution for one month; at 15-minute resolution for
            # one year; and at one-hour resolution for five years.
            'default' => {
                pattern    => '.*',
                retentions => '1m:7d,5m:30d,15m:1y,1h:5y',
            },
        },

        # Aggregation methods for whisper files.
        storage_aggregation => {
            'min' => {
                pattern           => '\.min$',
                xFilesFactor      => 0.1,
                aggregationMethod => 'min',
            },
            'max' => {
                pattern           => '\.max$',
                xFilesFactor      => 0.1,
                aggregationMethod => 'max',
            },
            'sum' => {
                pattern           => '\.count$',
                xFilesFactor      => 0,
                aggregationMethod => 'sum',
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
                line_receiver_interface   => '0.0.0.0',
                pickle_receiver_interface => '0.0.0.0',
                udp_receiver_interface    => '0.0.0.0',
                enable_udp_listener       => true,
                relay_method              => 'consistent-hashing',
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
    }

    class { '::graphite::web':
        admin_user        => $::passwords::graphite::user,
        admin_pass        => $::passwords::graphite::pass,
        secret_key        => $::passwords::graphite::secret_key,
        storage_dir       => $carbon_storage_dir,
        documentation_url => '//wikitech.wikimedia.org/wiki/Graphite',
    }


    include ::apache
    include ::apache::mod::uwsgi

    if $auth {
        # Production
        include ::passwords::ldap::production
        include ::apache::mod::authnz_ldap

        $ldap_authurl  = 'ldaps://virt1000.wikimedia.org virt0.wikimedia.org/ou=people,dc=wikimedia,dc=org?cn'
        $ldap_bindpass = $passwords::ldap::production::proxypass
        $ldap_binddn   = 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org'
        $ldap_groups   = [
            'cn=ops,ou=groups,dc=wikimedia,dc=org',
            'cn=nda,ou=groups,dc=wikimedia,dc=org',
            'cn=wmf,ou=groups,dc=wikimedia,dc=org'
        ]
        $auth_realm    = 'WMF Labs (use wiki login name not shell)'
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
    monitor_service { 'graphite':
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
        storage_dir => '/var/lib/carbon',
        auth => true,
    }

    include ::mediawiki::monitoring::graphite
    include ::eventlogging::monitoring::graphite
    include ::swift::monitoring::graphite

    # Monitor production 5xx rates
    monitor_graphite_threshold { 'reqstats_5xx':
        description     => 'HTTP 5xx req/min',
        metric          => 'reqstats.5xx',
        warning         => 250,
        critical        => 500,
        from            => '15min',
        nagios_critical => 'false'
    }

    # Will try to detect anomalies in the requests error ratio;
    # if 10% of the last 100 checks is out of forecasted bounds
    monitor_graphite_anomaly { 'requests_error_ratio':
        description  => 'HTTP error ratio anomaly detection',
        metric       => 'reqstats.5xx',
        warning      => 5,
        critical     => 10,
        check_window => 100,
        over         => true
    }
}

# == Class: role::graphite::labmon
#
# Sets up graphite instance for monitoring labs, running on production hardware.
# Instance is open to all, no password required to see metrics
class role::graphite::labmon {
    class { 'role::graphite::base':
        storage_dir => '/srv/carbon',
        auth        => false,
        hostname    => 'graphite.wmflabs.org',
    }

    include beta::monitoring::graphite
    include toollabs::monitoring::graphite
    include contint::monitoring::graphite
}
