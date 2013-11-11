class role::graphite {
    class { '::graphite':
        storage_schemas => {
            # Retain data at a one-minute resolution for one year and at a
            # ten-minute resolution for ten years. It's clear & easy to remember.
            # Avoid making this more complicated that it needs to be.
            'default' => {
                pattern    => '.*',
                retentions => '1m:1y,10m:10y',
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
        carbon_settings => {
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

            'relay' => {
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

    class { '::graphite::web': }

    nrpe::monitor_service { 'carbon':
        description  => 'Graphite Carbon',
        nrpe_command => '/sbin/carbonctl check',
    }
}
