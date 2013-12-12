class role::graphite {
    include ::passwords::graphite

    system::role { 'role::graphite':
        description => 'real-time metrics processor',
    }

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
            'min'     => {
                pattern           => '\.(lower|min)$',
                xFilesFactor      => 0.1,
                aggregationMethod => 'min',
            },
            'max'     => {
                pattern           => '\.(upper|max)$',
                xFilesFactor      => 0.1,
                aggregationMethod => 'max',
            },
            'sum'     => {
                pattern           => '\.(count|sum)$',
                xFilesFactor      => 0,
                aggregationMethod => 'sum',
            },
        },

        # All metric data goes through a single carbon-relay instance, which
        # forwards each data point to one of four carbon-cache instances, using a
        # consistent hash ring to distribute the load.
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
                line_receiver_interface   => '127.0.0.1',  # Only the relay binds to 0.0.0.0.
                pickle_receiver_interface => '127.0.0.1',
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

            ## Carbon relay ##

            'relay'   => {
                line_receiver_interface   => '0.0.0.0',
                pickle_receiver_interface => '0.0.0.0',
                relay_method              => 'consistent-hashing',
                destinations              => [
                    '127.0.0.1:2104:a',
                    '127.0.0.1:2204:b',
                    '127.0.0.1:2304:c',
                    '127.0.0.1:2404:d',
                ],
            },
        },
    }

    class { '::graphite::web':
        admin_user        => $::passwords::graphite::user,
        admin_pass        => $::passwords::graphite::pass,
        secret_key        => $::passwords::graphite::secret_key,
        documentation_url => '//wikitech.wikimedia.org/wiki/Graphite',
    }


    include ::apache
    include ::apache::mod::proxy
    include ::passwords::ldap::production

    file {
        '/etc/apache2/sites-available/graphite':
            content => template('apache/graphite.apache.erb');
        '/etc/apache2/sites-enabled/graphite':
            target  => '/etc/apache2/sites-available/graphite';
    }

    nrpe::monitor_service { 'carbon':
        description  => 'Graphite Carbon',
        nrpe_command => '/sbin/carbonctl check',
    }

    monitor_service { 'reqstats_5xx':
        description   => 'HTTP 5xx req/min',
        check_command => 'check_reqstats_5xx!http://graphite.wikimedia.org!-1hours!250!500',
    }
}
