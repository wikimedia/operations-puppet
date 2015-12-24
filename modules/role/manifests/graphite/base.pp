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

