# role/cache.pp
# cache::varnish role classes

# Virtual resources for the monitoring server
@monitoring::group { 'cache_text_eqiad':
    description => 'eqiad text Varnish',
}
@monitoring::group { 'cache_text_esams':
    description => 'esams text Varnish',
}
@monitoring::group { 'cache_text_ulsfo':
    description => 'ulsfo text Varnish',
}

@monitoring::group { 'cache_upload_eqiad':
    description => 'eqiad upload Varnish',
}
@monitoring::group { 'cache_upload_esams':
    description => 'esams upload Varnish',
}
@monitoring::group { 'cache_upload_ulsfo':
    description => 'ulsfo upload Varnish',
}

@monitoring::group { 'cache_bits_eqiad':
    description => 'eqiad bits Varnish',
}
@monitoring::group { 'cache_bits_esams':
    description => 'esams bits Varnish',
}
@monitoring::group { 'cache_bits_ulsfo':
    description => 'ulsfo bits Varnish',
}

@monitoring::group { 'cache_mobile_eqiad':
    description => 'eqiad mobile Varnish',
}
@monitoring::group { 'cache_mobile_esams':
    description => 'esams mobile Varnish',
}
@monitoring::group { 'cache_mobile_ulsfo':
    description => 'ulsfo mobile Varnish',
}

@monitoring::group { 'cache_parsoid_eqiad':
    description => 'Parsoid caches eqiad',
}

@monitoring::group { 'cache_misc_eqiad':
    description => 'Misc caches eqiad',
}

class role::cache {
    class configuration {
        include lvs::configuration

        $has_ganglia = hiera('has_ganglia', true)

        $active_nodes = {
            'production' => {
                'text' => {
                    'eqiad' => [
                        'cp1052.eqiad.wmnet',
                        'cp1053.eqiad.wmnet',
                        'cp1054.eqiad.wmnet',
                        'cp1055.eqiad.wmnet',
                        'cp1065.eqiad.wmnet',
                        'cp1066.eqiad.wmnet',
                        'cp1067.eqiad.wmnet',
                        'cp1068.eqiad.wmnet',
                    ],
                    'esams' => [
                        'amssq31.esams.wmnet',
                        'amssq32.esams.wmnet',
                        # T84133 'amssq33.esams.wmnet',
                        'amssq34.esams.wmnet',
                        'amssq35.esams.wmnet',
                        'amssq36.esams.wmnet',
                        'amssq37.esams.wmnet',
                        'amssq38.esams.wmnet',
                        'amssq39.esams.wmnet',
                        'amssq40.esams.wmnet',
                        'amssq41.esams.wmnet',
                        'amssq42.esams.wmnet',
                        'amssq43.esams.wmnet',
                        'amssq44.esams.wmnet',
                        'amssq45.esams.wmnet',
                        'amssq46.esams.wmnet',
                        'amssq47.esams.wmnet',
                        'amssq48.esams.wmnet',
                        'amssq49.esams.wmnet',
                        'amssq50.esams.wmnet',
                        'amssq51.esams.wmnet',
                        'amssq52.esams.wmnet',
                        'amssq53.esams.wmnet',
                        'amssq54.esams.wmnet',
                        'amssq55.esams.wmnet',
                        'amssq56.esams.wmnet',
                        'amssq57.esams.wmnet',
                        'amssq58.esams.wmnet',
                        'amssq59.esams.wmnet',
                        'amssq60.esams.wmnet',
                        'amssq61.esams.wmnet',
                        'amssq62.esams.wmnet',
                    ],
                    'ulsfo' => [
                        'cp4008.ulsfo.wmnet',
                        'cp4009.ulsfo.wmnet',
                        'cp4010.ulsfo.wmnet',
                        'cp4016.ulsfo.wmnet',
                        'cp4017.ulsfo.wmnet',
                        'cp4018.ulsfo.wmnet',
                    ]
                },
                'api' => {
                    'eqiad' => [],
                    'esams' => [],
                    'ulsfo' => [],
                },
                'bits' => {
                    'eqiad' => ['cp1056.eqiad.wmnet',
                                'cp1057.eqiad.wmnet',
                                'cp1069.eqiad.wmnet',
                                'cp1070.eqiad.wmnet',
                    ],
                    'esams' => [
                                'cp3019.esams.wmnet',
                                'cp3020.esams.wmnet',
                                'cp3021.esams.wmnet',
                                'cp3022.esams.wmnet',
                    ],
                    'ulsfo' => [
                                'cp4001.ulsfo.wmnet',
                                'cp4002.ulsfo.wmnet',
                                'cp4003.ulsfo.wmnet',
                                'cp4004.ulsfo.wmnet',
                    ],
                },
                'upload' => {
                    'eqiad' => [
                        'cp1048.eqiad.wmnet',
                        'cp1049.eqiad.wmnet',
                        'cp1050.eqiad.wmnet',
                        'cp1051.eqiad.wmnet',
                        'cp1061.eqiad.wmnet',
                        'cp1062.eqiad.wmnet',
                        'cp1063.eqiad.wmnet',
                        'cp1064.eqiad.wmnet',
                        #'cp1071.eqiad.wmnet',
                        #'cp1072.eqiad.wmnet',
                        #'cp1073.eqiad.wmnet',
                        #'cp1074.eqiad.wmnet',
                    ],
                    'esams' => [
                        'cp3003.esams.wmnet',
                        'cp3004.esams.wmnet',
                        'cp3005.esams.wmnet',
                        'cp3006.esams.wmnet',
                        'cp3007.esams.wmnet',
                        'cp3008.esams.wmnet',
                        'cp3009.esams.wmnet',
                        'cp3010.esams.wmnet',
                        'cp3015.esams.wmnet',
                        'cp3016.esams.wmnet',
                        'cp3017.esams.wmnet',
                        'cp3018.esams.wmnet',
                    ],
                    'ulsfo' => [
                        'cp4005.ulsfo.wmnet',
                        'cp4006.ulsfo.wmnet',
                        'cp4007.ulsfo.wmnet',
                        'cp4013.ulsfo.wmnet',
                        'cp4014.ulsfo.wmnet',
                        'cp4015.ulsfo.wmnet',
                    ],
                },
                'mobile' => {
                    'eqiad' => [
                                'cp1046.eqiad.wmnet',
                                'cp1047.eqiad.wmnet',
                                'cp1059.eqiad.wmnet',
                                'cp1060.eqiad.wmnet',
                    ],
                    'esams' => [
                                # T92306 'cp3011.esams.wmnet', # needs-jessie-install
                                'cp3012.esams.wmnet',
                                'cp3013.esams.wmnet',
                                'cp3014.esams.wmnet',
                    ],
                    'ulsfo' => [
                                'cp4011.ulsfo.wmnet',
                                'cp4012.ulsfo.wmnet',
                                'cp4019.ulsfo.wmnet',
                                'cp4020.ulsfo.wmnet',
                    ]
                },
                'parsoid' => {
                    'eqiad' => [
                        'cp1045.eqiad.wmnet',
                        'cp1058.eqiad.wmnet',
                    ],
                    'esams' => [],
                    'ulsfo' => []
                },
                'misc' => {
                    'eqiad' => [
                        'cp1043.eqiad.wmnet',
                        'cp1044.eqiad.wmnet',
                    ],
                    'esams' => [],
                    'ulsfo' => [],
                },
                'cxserver' => {
                    'eqiad' => 'cxserver.svc.eqiad.wmnet',
                },
                'citoid' => {
                    'eqiad' => 'citoid.svc.eqiad.wmnet',
                },
                'restbase' => {
                    'eqiad' => 'restbase.svc.eqiad.wmnet',
                },
            },
            'labs' => {
                'api'    => {
                    'eqiad' => '127.0.0.1',
                },
                'bits'   => {
                    'eqiad' => '127.0.0.1',
                },
                'mobile' => {
                    'eqiad' => '127.0.0.1',
                },
                'text'   => {
                    'eqiad' => '127.0.0.1',
                },
                'upload' => {
                    'eqiad' => '127.0.0.1',
                },
                'parsoid' => {
                    'eqiad' => '127.0.0.1',
                },
                'cxserver' => {
                    'eqiad' => 'cxserver-beta.wmflabs.org',
                },
                'citoid' => {
                    'eqiad' => 'citoid.wmflabs.org',
                },
            },
        }

        $decommissioned_nodes = {
            'text' => {
                'eqiad' => [

                ],
                'esams' => [
                    'knsq1.knams.wikimedia.org',
                    'knsq2.knams.wikimedia.org',
                    'knsq3.knams.wikimedia.org',
                    'knsq4.knams.wikimedia.org',
                    'knsq5.knams.wikimedia.org',
                    'knsq6.knams.wikimedia.org',
                    'knsq7.knams.wikimedia.org',
                    'knsq23.knams.wikimedia.org',
                    'knsq24.knams.wikimedia.org',
                    'knsq25.knams.wikimedia.org',
                    'knsq26.knams.wikimedia.org',
                    'knsq27.knams.wikimedia.org',
                    'knsq28.knams.wikimedia.org',
                    'knsq29.knams.wikimedia.org',
                    'knsq30.knams.wikimedia.org',
                ]
            },
            'api' => {
                'eqiad' => [],
                'esams' => [],
            },
            'bits' => {
                'eqiad' => [],
                'esams' => [
                    'knsq1.esams.wikimedia.org',
                    'knsq2.esams.wikimedia.org',
                    'knsq4.esams.wikimedia.org',
                    'knsq5.esams.wikimedia.org',
                    'knsq6.esams.wikimedia.org',
                    'knsq7.esams.wikimedia.org',
                ],
                'ulsfo' => [],
            },
            'upload' => {
                'eqiad' => [
                    'cp1021.eqiad.wmnet',
                    'cp1022.eqiad.wmnet',
                    'cp1023.eqiad.wmnet',
                    'cp1024.eqiad.wmnet',
                    'cp1025.eqiad.wmnet',
                    'cp1026.eqiad.wmnet',
                    'cp1027.eqiad.wmnet',
                    'cp1028.eqiad.wmnet',
                    'cp1029.eqiad.wmnet',
                    'cp1030.eqiad.wmnet',
                    'cp1031.eqiad.wmnet',
                    'cp1032.eqiad.wmnet',
                    'cp1033.eqiad.wmnet',
                    'cp1034.eqiad.wmnet',
                    'cp1035.eqiad.wmnet',
                    'cp1036.eqiad.wmnet',
                ],
                'esams' => [
                    'knsq8.knams.wikimedia.org',
                    'knsq9.knams.wikimedia.org',
                    'knsq10.knams.wikimedia.org',
                    'knsq11.knams.wikimedia.org',
                    'knsq12.knams.wikimedia.org',
                    'knsq13.knams.wikimedia.org',
                    'knsq14.knams.wikimedia.org',
                    'knsq15.knams.wikimedia.org'
                ],
                'ulsfo' => [],
            },
            'mobile' => {
                'eqiad' => ['cp1041.eqiad.wmnet', 'cp1042.eqiad.wmnet'],
                'esams' => [],
                'ulsfo' => [],
            },
            'parsoid' => {
                'eqiad' => [],
                'esams' => [],
                'ulsfo' => [],
            },
            'misc' => {
                'eqiad' => [],
                'esams' => [],
                'ulsfo' => [],
            }
        }

        $backends = {
            'production' => {
                'appservers'        => $lvs::configuration::lvs_service_ips['production']['apaches'],
                'api'               => $lvs::configuration::lvs_service_ips['production']['api'],
                'rendering'         => $lvs::configuration::lvs_service_ips['production']['rendering'],
                'bits' => {
                    'eqiad' => flatten([$lvs::configuration::lvs_service_ips['production']['bits']['eqiad']['bitslb']]),
                },
                'bits_appservers' => {
                    'eqiad' => flatten([$lvs::configuration::lvs_service_ips['production']['apaches']['eqiad']]),
                },
                'test_appservers' => {
                    'eqiad' => [ 'mw1017.eqiad.wmnet' ],
                },
                'parsoid' => $lvs::configuration::lvs_service_ips['production']['parsoid']
            },
            'labs' => {
                'appservers' => {
                    'eqiad' => [
                        '10.68.17.170',  # deployment-mediawiki01
                        '10.68.16.127', # deployment-mediawiki02
                    ],
                },
                'api' => {
                    'eqiad' => [
                        '10.68.17.170',  # deployment-mediawiki01
                        '10.68.16.127', # deployment-mediawiki02
                    ],
                },
                'bits' => {
                    'eqiad' => [
                        '10.68.17.170',  # deployment-mediawiki01
                        '10.68.16.127', # deployment-mediawiki02
                    ],
                },
                'bits_appservers' => {
                    'eqiad' => [
                        '10.68.17.170',  # deployment-mediawiki01
                        '10.68.16.127', # deployment-mediawiki02
                    ],
                },
                'rendering' => {
                    'eqiad' => [
                        '10.68.17.170',  # deployment-mediawiki01
                        '10.68.16.127', # deployment-mediawiki02
                    ],
                },
                'test_appservers' => {
                    'eqiad' => [ '10.68.17.170' ],  # deployment-mediawiki01
                },
                'parsoid' => {
                    'eqiad' => [ '10.68.16.120' ],  # deployment-parsoid05
                }
            }
        }
    }

    class varnish::logging {
        if $::realm == 'production' {
            $webrequest_multicast_relay_host = '208.80.154.73' # gadoinium

            $cliargs = '-m RxRequest:^(?!PURGE$) -D'
            varnish::logging { 'multicast_relay':
                    listener_address => $webrequest_multicast_relay_host,
                    port             => '8419',
                    cli_args         => $cliargs,
            }

            varnish::logging { 'erbium':
                    listener_address => '10.64.32.135',
                    port             => '8419',
                    cli_args         => $cliargs,
            }
        }
    }

    # == Class varnish::statsd
    # Installs a local statsd instance for aggregating and serializing
    # stats before sending them off to a remote statsd instance.
    class varnish::statsd {
        class { '::txstatsd':
            settings => {
                statsd => {
                    'carbon-cache-host'          => "graphite-in.eqiad.wmnet",
                    'carbon-cache-port'          => 2004,
                    'listen-port'                => 8125,
                    'statsd-compliance'          => 0,
                    'prefix'                     => '',
                    'max-queue-size'             => 1000 * 1000,
                    'max-datapoints-per-message' => 10 * 1000,
                    'instance-name'              => "statsd.${::hostname}",
                },
            },
        }
    }

    # == Class varnish::kafka
    # Base class for instances of varnishkafka on cache servers.
    #
    class varnish::kafka {
        require role::analytics::kafka::config

        # Get a list of kafka brokers for the currently configured $kafka_cluster_name.
        # In production this will be 'eqiad' always, since we only have one Kafka cluster there.
        # Even though $kafka_cluster_name should hardcoded to 'eqiad' in ...kafka::config,
        # we hardcode it again here, just to be sure it doesn't accidentally get changed
        # if we add new Kafka clusters later.
        $kafka_cluster_name = $::realm ? {
            'production' => 'eqiad',
            'labs'       => $role::analytics::kafka::config::kafka_cluster_name,
        }

        $kafka_brokers = keys($role::analytics::kafka::config::cluster_config[$kafka_cluster_name])

        # varnishkafka will use a local statsd instance for
        # using logster to collect metrics.
        include role::cache::varnish::statsd

        # Make sure varnishkafka rsyslog file is in place properly.
        rsyslog::conf { 'varnishkafka':
            source   => 'puppet:///files/varnish/varnishkafka_rsyslog.conf',
            priority => 70,
        }

        # Make sure that Rsyslog::Conf['varnishkafka'] happens
        # before the first varnishkafka::instance
        # so that logs will go to rsyslog the first time puppet
        # sets up varnishkafka.
        Rsyslog::Conf['varnishkafka'] -> Varnishkafka::Instance <|  |>

        # Make sure varnishes are configured and started for the first time
        # before the instances as well, or they fail to start initially...
        Service <| tag == 'varnish_instance' |> -> Varnishkafka::Instance <| |>
    }

    # == Class varnish::kafka::webrequest
    # Sets up a varnishkafka instance producing varnish
    # webrequest logs to the analytics Kafka brokers in eqiad.
    #
    # == Parameters
    # $topic            - the name of kafka topic to which to send messages
    # $varnish_name - the name of the varnish instance to read shared logs from.  Default 'frontend'
    # $varnish_svc_name - the name of the init unit for the above, default 'varnish-frontend'
    #
    class varnish::kafka::webrequest(
        $topic,
        $varnish_name = 'frontend',
        $varnish_svc_name = 'varnish-frontend'
    ) inherits role::cache::varnish::kafka
    {
        varnishkafka::instance { 'webrequest':
            brokers                      => $kafka_brokers,
            topic                        => $topic,
            format_type                  => 'json',
            compression_codec            => 'snappy',
            varnish_name                 => $varnish_name,
            varnish_svc_name             => $varnish_svc_name,
            # Note: fake_tag tricks varnishkafka into allowing hardcoded string into a JSON field.
            # Hardcoding the $fqdn into hostname rather than using %l to account for
            # possible slip ups where varnish only writes the short hostname for %l.
            format                       => "%{fake_tag0@hostname?${::fqdn}}x %{@sequence!num?0}n %{%FT%T@dt}t %{Varnish:time_firstbyte@time_firstbyte!num?0.0}x %{@ip}h %{Varnish:handling@cache_status}x %{@http_status}s %{@response_size!num?0}b %{@http_method}m %{Host@uri_host}i %{@uri_path}U %{@uri_query}q %{Content-Type@content_type}o %{Referer@referer}i %{X-Forwarded-For@x_forwarded_for}i %{User-Agent@user_agent}i %{Accept-Language@accept_language}i %{X-Analytics@x_analytics}o %{Range@range}i %{X-Cache@x_cache}o",
            message_send_max_retries     => 3,
            # At ~6000 msgs per second, 500000 messages is over 1 minute
            # of buffering, which should be more than enough.
            queue_buffering_max_messages => 500000,
            # bits varnishes can do about 6000 reqs / sec each.
            # We want to send batches at least once a second.
            batch_num_messages           => 6000,
            # On caches with high traffic (bits and upload), we have seen
            # message drops from esams during high load time with a large
            # request ack timeout (it was 30 seconds).
            # The vanrishkafka buffer gets too full and it drops messages.
            # Perhaps this is a buffer bloat problem.
            # Note that varnishkafka will retry a timed-out produce request.
            topic_request_timeout_ms     => 2000,
            # By requiring 2 ACKs per message batch, we survive a
            # single broker dropping out of its leader role,
            # without seeing lost messages.
            topic_request_required_acks  => '2',
            # Write out stats to varnishkafka.stats.json
            # this often.  This is set at 15 so that
            # stats will be fresh when polled from gmetad.
            log_statistics_interval      => 15,
        }

        varnishkafka::monitor { 'webrequest':
            # The primary webrequest varnishkafka instance was formerly the
            # only one running, so we don't prefix its Ganglia metric keys.
            key_prefix => '',
        }

        # Generate icinga alert if varnishkafka is not running.
        nrpe::monitor_service { 'varnishkafka':
            description  => 'Varnishkafka log producer',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1: -C varnishkafka',
            require      => Class['::varnishkafka'],
        }

        # Extract cache type name from topic for use in statsd prefix.
        # There is probably a better way to do this.
        $cache_type = regsubst($topic, '^webrequest_(.+)$', '\1')
        $graphite_metric_prefix = "varnishkafka.${::hostname}.webrequest.${cache_type}"

        # Test using logster to send varnishkafka stats to statsd -> graphite.
        # This may be moved into the varnishkafka module.
        logster::job { 'varnishkafka-webrequest':
            minute          => '*/1',
            parser          => 'JsonLogster',
            logfile         => "/var/cache/varnishkafka/webrequest.stats.json",
            logster_options => "-o statsd --statsd-host=localhost:8125 --metric-prefix=${graphite_metric_prefix}",
            require         => Class['role::cache::varnish::statsd'],
        }

        # Generate an alert if too many delivery report errors per minute
        # (logster only reports once a minute)
        monitoring::graphite_threshold { 'varnishkafka-kafka_drerr':
            description     => 'Varnishkafka Delivery Errors per minute',
            metric          => "derivative(${graphite_metric_prefix}.varnishkafka.kafka_drerr.value)",
            # warn if more than 0 errors per minute in the last 10 minutes
            warning         => 0,
            # critical if more than 20000 errors per minute in the last 10 minutes
            critical        => 20000,
            from            => '10min',
            nagios_critical => 'false',
            require         => Logster::Job['varnishkafka-webrequest'],
        }
    }

    # == Class varnish::kafka::statsv
    # Sets up a varnishkafka logging endpoint for collecting
    # application level metrics. We are calling this system
    # statsv, as it is similar to statsd, but uses varnish
    # as its logging endpoint.
    #
    # == Parameters
    # $varnish_name - the name of the varnish instance to read shared logs from.  Default $::hostname
    # $varnish_svc_name - the name of the varnish init service to read shared logs from.  Default 'varnish'
    #
    class varnish::kafka::statsv(
        $varnish_name = $::hostname,
        $varnish_svc_name = 'varnish',
    ) inherits role::cache::varnish::kafka
    {
        $format  = "%{fake_tag0@hostname?${::fqdn}}x %{%FT%T@dt}t %{@ip}h %{@uri_path}U %{@uri_query}q %{User-Agent@user_agent}i"

        varnishkafka::instance { 'statsv':
            brokers           => $kafka_brokers,
            format            => $format,
            format_type       => 'json',
            topic             => 'statsv',
            varnish_name      => $varnish_name,
            varnish_svc_name  => $varnish_svc_name,
            varnish_opts      => { 'm' => 'RxURL:^/statsv[/?]', },
            # By requiring 2 ACKs per message batch, we survive a
            # single broker dropping out of its leader role,
            # without seeing lost messages.
            topic_request_required_acks  => '2',
        }

        varnishkafka::monitor { 'statsv': }
    }

    class varnish::kafka::eventlogging(
        $varnish_name = $::hostname,
        $varnish_svc_name = 'varnish',
    ) inherits role::cache::varnish::kafka
    {
        varnishkafka::instance { 'eventlogging':
            brokers           => $kafka_brokers,
            # Note that this format uses literal tab characters.
            format            => '%q	%l	%n	%{%FT%T}t	%h	"%{User-agent}i"',
            format_type       => 'string',
            topic             => 'eventlogging-client-side',
            varnish_name      => $varnish_name,
            varnish_svc_name  => $varnish_svc_name,
            varnish_opts      => { 'm' => 'RxURL:^/beacon/event\.gif\?.' },
            topic_request_required_acks  => '-1',
        }
    }

    class varnish::logging::eventlistener {
        $event_listener = $::realm ? {
            'production' => '10.64.21.123',  # vanadium
            'labs'       => '10.68.16.52',   # deployment-eventlogging02
        }

        varnish::logging { 'vanadium' :
            listener_address => $event_listener,
            port             => '8422',
            instance_name    => '',
            cli_args         => '-m RxURL:^/event\.gif\?. -D',
            log_fmt          => '%q\t%l\t%n\t%t\t%h\t"%{User-agent}i"',
            monitor          => false,
        }
    }

    define localssl($certname, $do_ocsp=false, $server_name=$::fqdn, $server_aliases=[], $default_server=false) {
        # Assumes that LVS service IPs are setup elsewhere

        install_certificate { $certname:
            before => Protoproxy::Localssl[$name],
        }

        protoproxy::localssl { $name:
            proxy_server_cert_name => $certname,
            upstream_port          => '80',
            default_server         => $default_server,
            server_name            => $server_name,
            server_aliases         => $server_aliases,
            do_ocsp                => $do_ocsp,
        }
    }

    class ssl::sni {
        #TODO: kill the old wmf_ca
        include certificates::wmf_ca
        include certificates::wmf_ca_2014_2017
        include role::protoproxy::ssl::common

        # Test OCSP on cp1008 only initially
        if $::hostname == 'cp1008' {
            $ocsp_test = true
        }
        else {
            $ocsp_test = false
        }

        localssl { 'unified':
            certname => 'uni.wikimedia.org',
            default_server => true,
            do_ocsp => $ocsp_test,
        }

        define sni_cert() {
            # Test OCSP on cp1008 only initially
            if $::hostname == 'cp1008' {
                $ocsp_test = true
            }
            else {
                $ocsp_test = false
            }

            localssl { $name:
                certname => "sni.${name}",
                server_name => $name,
                server_aliases => ["*.${name}"],
                do_ocsp => $ocsp_test,
            }
        }

        sni_cert {
            'zero.wikipedia.org':;
            'm.wikipedia.org':;
            'wikipedia.org':;
            'm.wikimedia.org':;
            'wikimedia.org':;
            'm.wiktionary.org':;
            'wiktionary.org':;
            'm.wikiquote.org':;
            'wikiquote.org':;
            'm.wikibooks.org':;
            'wikibooks.org':;
            'm.wikisource.org':;
            'wikisource.org':;
            'm.wikinews.org':;
            'wikinews.org':;
            'm.wikiversity.org':;
            'wikiversity.org':;
            'm.wikidata.org':;
            'wikidata.org':;
            'm.wikivoyage.org':;
            'wikivoyage.org':;
            'm.wikimediafoundation.org':;
            'wikimediafoundation.org':;
            'm.mediawiki.org':;
            'mediawiki.org':;
        }

        monitoring::service { 'https':
            description   => 'HTTPS',
            check_command => 'check_sslxNN',
        }

        # ordering ensures nginx/varnish config/service-start are
        #  not intermingled during initial install where they could
        #  have temporary conflicts on binding port 80
        Service['nginx'] -> Service<| tag == 'varnish_instance' |>
    }

    # As above, but for misc instead of generic prod
    class ssl::misc {
        #TODO: kill the old wmf_ca
        include certificates::wmf_ca
        include certificates::wmf_ca_2014_2017
        include role::protoproxy::ssl::common

        localssl {
            'wikimedia.org':
                certname => 'sni.wikimedia.org',
                server_name => 'wikimedia.org',
                server_aliases => ['*.wikimedia.org'],
                default_server => true;
            'wmfusercontent.org':
                certname => 'star.wmfusercontent.org',
                server_name => 'wmfusercontent.org',
                server_aliases => ['*.wmfusercontent.org'];
            'planet.wikimedia.org':
                certname       => 'star.planet.wikimedia.org',
                server_name    => 'planet.wikimedia.org',
                server_aliases => ['*.planet.wikimedia.org'];
        }
    }

    # Ancestor class for all Varnish clusters
    class varnish::base {
        include lvs::configuration
        include role::cache::configuration
        include network::constants

        if $::realm == 'production' {
            include ::admin
        }

        # Any changes here will affect all descendent Varnish clusters
        # unless they're overridden!
        if $::site in ['eqiad'] {
            $cluster_tier = 1
            $default_backend = 'backend'
        } else {
            $cluster_tier = 2
            $default_backend = $::mw_primary
        }
        $wikimedia_networks = flatten([$network::constants::all_networks, '127.0.0.0/8', '::1/128'])

        $storage_partitions = $::realm ? {
            'production' => ['sda3', 'sdb3'],
            'labs'       => ['vdb'],
        }

        # This seems to prevent long term memory fragmentation issues that
        #  can cause VM perf issues.  This seems to be less necessary on jessie
        #  with other assorted fixes in place, and we could experiment with
        #  removing it entirely at a later time when things are more stable.
        #  (watch for small but increasing sys% spikes on upload caches if so,
        #  may take days to have real effect).
        cron { 'varnish_vm_compact_cron':
            command => 'echo 1 >/proc/sys/vm/compact_memory',
            user    => 'root',
            minute  => '*',
        }

        #class { "varnish::packages": version => "3.0.3plus~rc1-wm5" }

        # Prod-specific performance tweaks
        if $::realm == 'production' {
            include cpufrequtils # defaults to "performance"

            # Bump min_free_kbytes to ensure network buffers are available quickly
            #   without having to evict cache on the spot
            vm::min_free_kbytes { 'cache':
                pct => 2,
                min => 131072,
                max => 1048576,
            }

            # RPS/RSS to spread network i/o evenly
            interface::rps { 'eth0': }

            # flush vm more steadily in the background. helps avoid large performance
            #   spikes related to flushing out disk write cache.
            sysctl::parameters { 'cache_role_vm_settings':
                values => {
                    'vm.dirty_ratio'            => 40,  # default 20
                    'vm.dirty_background_ratio' => 5,   # default 10
                    'vm.dirty_expire_centisecs' => 500, # default 3000
                },
            }

            # Disable TCP SSR (slow-start restart). SSR resets the congestion
            # window of connections that have gone idle, which means it has a
            # tendency to reset the congestion window of HTTP keepalive and SPDY
            # connections, which are characterized by short bursts of activity
            # separated by long idle times.
            sysctl::parameters { 'disable_ssr':
                values => { 'net.ipv4.tcp_slow_start_after_idle' => 0 },
            }
        }

        # mma: mmap addrseses for fixed persistent storage on x86_64 Linux:
        #  This scheme fits 4x fixed memory mappings of up to 4TB each
        #  into the range 0x500000000000 - 0x5FFFFFFFFFFF, which on
        #  x86_64 Linux is in the middle of the user address space and thus
        #  unlikely to ever be used by normal, auto-addressed allocations,
        #  as those grow in from the edges (typically from the top, but
        #  possibly from the bottom depending).  Regardless of which
        #  direction heap grows from, there's 32TB or more for normal
        #  allocations to chew through before they reach our fixed range.
        $mma0 = 0x500000000000
        $mma1 = 0x540000000000
        $mma2 = 0x580000000000
        $mma3 = 0x5C0000000000

        # These regexes are for optimization of PURGE traffic by having
        #   non-upload sites ignore upload purges and having upload
        #   ignore everything but upload purges via purge_host_regex
        #   in child classes where warranted.
        $purge_host_only_upload_re = $::realm ? {
            'production' => '^upload\.wikimedia\.org$',
            'labs'       => '^upload\.beta\.wmflabs\.org$',
        }
        $purge_host_not_upload_re = $::realm ? {
            'production' => '^(?!upload\.wikimedia\.org)',
            'labs' => '^(?!upload\.beta\.wmflabs\.org)',
        }
    }

    # Ancestor class for common resources of 1-layer clusters
    class varnish::1layer inherits role::cache::varnish::base {
        # Any changes here will affect all descendent Varnish clusters
        # unless they're overridden!
        $backend_weight = 10

        if $::role::cache::configuration::has_ganglia {
            include varnish::monitoring::ganglia
        }
    }

    # Ancestor class for common resources of 2-layer clusters
    class varnish::2layer inherits role::cache::varnish::base {
        # Any changes here will affect all descendent Varnish clusters
        # unless they're overridden!
        $backend_weight = 100

        if $::realm == 'production' {
            $storage_size_main = $::hostname ? {
                'cp1008'                => 117, # Intel X-25M 160G
                /^amssq/                => 117, # Intel X-25M 160G
                /^cp104[34]/            => 117, # Intel X-25M 160G
                /^cp30(0[3-9]|1[0-4])$/ => 460, # Intel M320 600G via H710
                /^cp301[5-8]$/          => 225, # Intel M320 300G via H710
                default                 => 360, # Intel S3700 400G
            }
        }
        else {
            # for upload on jessie, bigobj is main/6, so 6 is functional minimum here.
            $storage_size_main = 6
        }

        # Ganglia monitoring
        if $::role::cache::configuration::has_ganglia{
            class { 'varnish::monitoring::ganglia':
                varnish_instances => [ '', 'frontend' ],
            }
        }
    }

    class text inherits role::cache::varnish::2layer {
        $memory_storage_size = floor((0.125 * $::memorysize_mb / 1024.0) + 0.5) # 1/8 of total mem

        system::role { 'role::cache::text':
            description => 'text Varnish cache server',
        }

        if $::realm == 'production' {
            include role::cache::ssl::sni
        }

        require geoip
        require geoip::dev # for VCL compilation using libGeoIP

        class { 'lvs::realserver':
            realserver_ips => $lvs::configuration::lvs_service_ips[$::realm]['text'][$::site],
        }

        $varnish_be_directors = {
            1 => {
                'backend'           => $role::cache::configuration::backends[$::realm]['appservers'][$::mw_primary],
                'api'               => $role::cache::configuration::backends[$::realm]['api'][$::mw_primary],
                'rendering'         => $role::cache::configuration::backends[$::realm]['rendering'][$::mw_primary],
                'test_wikipedia'    => $role::cache::configuration::backends[$::realm]['test_appservers'][$::mw_primary],
            },
            2 => {
                'eqiad' => $role::cache::configuration::active_nodes[$::realm]['text']['eqiad'],
            },
        }

        include standard
        include nrpe

        #class { "varnish::packages": version => "3.0.3plus~rc1-wm13" }

        varnish::setup_filesystem{ $storage_partitions:
            before => Varnish::Instance['text-backend']
        }

        class { 'varnish::htcppurger':
            varnish_instances => [ '127.0.0.1:80', '127.0.0.1:3128' ],
        }

        if $::role::cache::configuration::has_ganglia {
            include varnish::monitoring::ganglia::vhtcpd
        }

        $runtime_params = $::site ? {
            #'esams' => ['prefer_ipv6=on','default_ttl=2592000'],
            default => ['default_ttl=2592000'],
        }

        $storage_conf = $::realm ? {
            'production' => $::hostname ? {
                /^amssq(4[7-9]|[56][0-9])$/ => "-s main2=persistent,/srv/sdb3/varnish.main2,${storage_size_main}G,$mma0", # sda is an HDD, sdb is an SSD
                default => "-s main1=persistent,/srv/sda3/varnish.main1,${storage_size_main}G,$mma0 -s main2=persistent,/srv/sdb3/varnish.main2,${storage_size_main}G,$mma1",
            },
            'labs'  => "-s main1=persistent,/srv/vdb/varnish.main1,${storage_size_main}G,$mma0 -s main2=persistent,/srv/vdb/varnish.main2,${storage_size_main}G,$mma1",
        }

        $director_type_cluster = $cluster_tier ? {
            1       => 'random',
            default => 'chash',
        }

        varnish::instance { 'text-backend':
            name               => '',
            vcl                => 'text-backend',
            extra_vcl          => ['text-common'],
            port               => 3128,
            admin_port         => 6083,
            runtime_parameters => $runtime_params,
            storage            => $storage_conf,
            directors          => $varnish_be_directors[$cluster_tier],
            director_type      => $director_type_cluster,
            vcl_config         => {
                'default_backend'  => $default_backend,
                'retry503'         => 1,
                'retry5xx'         => 0,
                'cache4xx'         => '1m',
                'purge_host_regex' => $purge_host_not_upload_re,
                'cluster_tier'     => $cluster_tier,
                'layer'            => 'backend',
                'ssl_proxies'      => $wikimedia_networks,
            },
            backend_options    => [
                {
                    'backend_match' => '^cp[0-9]+\.eqiad\.wmnet$',
                    'port'          => 3128,
                    'probe'         => 'varnish',
                },
                {
                    'backend_match'   => '^mw1017\.eqiad\.wmnet$',
                    'max_connections' => 20,
                },
                {
                    'port'                  => 80,
                    'connect_timeout'       => '5s',
                    'first_byte_timeout'    => '180s',
                    'between_bytes_timeout' => '4s',
                    'max_connections'       => 1000,
                    'weight'                => $backend_weight,
                }],
            wikimedia_networks => $wikimedia_networks,
        }

        varnish::instance { 'text-frontend':
            name            => 'frontend',
            vcl             => 'text-frontend',
            extra_vcl       => ['text-common'],
            port            => 80,
            admin_port      => 6082,
            storage         => "-s malloc,${memory_storage_size}G",
            directors       => {
                'backend' => $role::cache::configuration::active_nodes[$::realm]['text'][$::site],
            },
            director_type   => 'chash',
            vcl_config      => {
                'retry503'         => 1,
                'retry5xx'         => 0,
                'cache4xx'         => '1m',
                'purge_host_regex' => $purge_host_not_upload_re,
                'cluster_tier'     => $cluster_tier,
                'layer'            => 'frontend',
                'ssl_proxies'      => $wikimedia_networks,
            },
            backend_options => [
                {
                    'port'                  => 3128,
                    'connect_timeout'       => '5s',
                    'first_byte_timeout'    => '185s',
                    'between_bytes_timeout' => '2s',
                    'max_connections'       => 100000,
                    'probe'                 => 'varnish',
                    'weight'                => $backend_weight,
                }],
            cluster_options => {
                'enable_geoiplookup' => true,
            },
        }

        include role::cache::varnish::logging

        # HTCP packet loss monitoring on the ganglia aggregators
        if $ganglia_aggregator and $::site != 'esams' {
            include misc::monitoring::htcp-loss
        }

        # ToDo: Remove production conditional once this works
        # is verified to work in labs.
        if $::realm == 'production' {
            # Install a varnishkafka producer to send
            # varnish webrequest logs to Kafka.
            class { 'role::cache::varnish::kafka::webrequest':
                topic => 'webrequest_text',
            }
        }
    }

    class upload inherits role::cache::varnish::2layer {
        $memory_storage_size = floor((0.083 * $::memorysize_mb / 1024.0) + 0.5) # 1/12 of total mem

        system::role { 'role::cache::upload':
            description => 'upload Varnish cache server',
        }

        if $::realm == 'production' {
            include role::cache::ssl::sni
        }

        class { 'lvs::realserver':
            realserver_ips => $lvs::configuration::lvs_service_ips[$::realm]['upload'][$::site],
        }

        $varnish_be_directors = {
            1 => {
                'backend'   => $lvs::configuration::lvs_service_ips[$::realm]['swift'][$::mw_primary],
                'rendering' => $role::cache::configuration::backends[$::realm]['rendering'][$::mw_primary],
            },
            2 => {
                'eqiad' => $role::cache::configuration::active_nodes[$::realm]['upload']['eqiad']
            }
        }

        $default_backend = $cluster_tier ? {
            1       => 'backend',
            default => 'eqiad',
        }

        if $cluster_tier == 1 {
            $director_retries = 2
        } else {
            $director_retries = $backend_weight * 4
        }

        include standard
        include nrpe

        $storage_partitions = $::realm ? {
            'production' => ['sda3', 'sdb3'],
            'labs' => ['vdb']
        }
        varnish::setup_filesystem{ $storage_partitions:
            before => Varnish::Instance['upload-backend'],
        }

        class { 'varnish::htcppurger':
            varnish_instances => [ '127.0.0.1:80', '127.0.0.1:3128' ],
        }

        if $::role::cache::configuration::has_ganglia {
            include varnish::monitoring::ganglia::vhtcpd
        }

        case $::realm {
            'production': {
                $cluster_options = {
                    'upload_domain' => 'upload.wikimedia.org',
                    'top_domain'    => 'org',
                }
            }
            'labs': {
                $cluster_options = {
                    'upload_domain' => 'upload.beta.wmflabs.org',
                    'top_domain'    => 'beta.wmflabs.org',
                    'do_gzip'       => true,
                }
            }
        }

        $runtime_params = $::site ? {
            #'esams' => ['prefer_ipv6=on','default_ttl=2592000'],
            default  => ['default_ttl=2592000'],
        }


        $storage_size_bigobj = floor($storage_size_main / 6)
        $storage_size_up = $storage_size_main - $storage_size_bigobj
        $storage_conf =  $::realm ? {
            'production' => "-s main1=persistent,/srv/sda3/varnish.main1,${storage_size_up}G,$mma0 -s main2=persistent,/srv/sdb3/varnish.main2,${storage_size_up}G,$mma1 -s bigobj1=file,/srv/sda3/varnish.bigobj1,${storage_size_bigobj}G -s bigobj2=file,/srv/sdb3/varnish.bigobj2,${storage_size_bigobj}G",
            'labs'       => "-s main1=persistent,/srv/vdb/varnish.main1,${storage_size_main}G,$mma0 -s main2=persistent,/srv/vdb/varnish.main2,${storage_size_main}G,$mma1 -s bigobj1=file,/srv/vdb/varnish.bigobj1,${storage_size_bigobj}G -s bigobj2=file,/srv/vdb/varnish.bigobj2,${storage_size_bigobj}G"
        }

        $director_type_cluster = $cluster_tier ? {
            1       => 'random',
            default => 'chash',
        }

        varnish::instance { 'upload-backend':
            name               => '',
            vcl                => 'upload-backend',
            port               => 3128,
            admin_port         => 6083,
            runtime_parameters => $runtime_params,
            storage            => $storage_conf,
            directors          => $varnish_be_directors[$cluster_tier],
            director_type      => $director_type_cluster,
            director_options   => {
                'retries' => $director_retries,
            },
            vcl_config         => {
                'default_backend'  => $default_backend,
                'retry5xx'         => 0,
                'cache4xx'         => '1m',
                'purge_host_regex' => $purge_host_only_upload_re,
                'cluster_tier'     => $cluster_tier,
                'layer'            => 'backend',
                'ssl_proxies'      => $wikimedia_networks,
            },
            backend_options    => [
                {
                    'backend_match' => '^cp[0-9]+\.eqiad.wmnet$',
                    'port'          => 3128,
                    'probe'         => 'varnish',
                },
                {
                    'port'                  => 80,
                    'connect_timeout'       => '5s',
                    'first_byte_timeout'    => '35s',
                    'between_bytes_timeout' => '4s',
                    'max_connections'       => 1000,
                    'weight'                => $backend_weight,
                }],
            cluster_options    => $cluster_options,
            wikimedia_networks => $wikimedia_networks,
        }

        varnish::instance { 'upload-frontend':
            name            => 'frontend',
            vcl             => 'upload-frontend',
            port            => 80,
            admin_port      => 6082,
            storage         => "-s malloc,${memory_storage_size}G",
            directors       => {
                'backend' => $role::cache::configuration::active_nodes[$::realm]['upload'][$::site],
            },
            director_type   => 'chash',
            vcl_config      => {
                'retry5xx'         => 0,
                'cache4xx'         => '1m',
                'purge_host_regex' => $purge_host_only_upload_re,
                'cluster_tier'     => $cluster_tier,
                'layer'            => 'frontend',
                'ssl_proxies'      => $wikimedia_networks,
            },
            backend_options => [
                {
                    'port'                  => 3128,
                    'connect_timeout'       => '5s',
                    'first_byte_timeout'    => '35s',
                    'between_bytes_timeout' => '2s',
                    'max_connections'       => 100000,
                    'probe'                 => 'varnish',
                    'weight'                => $backend_weight,
                }],
            cluster_options => $cluster_options,
        }

        include role::cache::varnish::logging

        # HTCP packet loss monitoring on the ganglia aggregators
        if $ganglia_aggregator and $::site != 'esams' {
            include misc::monitoring::htcp-loss
        }

        # ToDo: Remove production conditional once this works
        # is verified to work in labs.
        if $::realm == 'production' {
            # Install a varnishkafka producer to send
            # varnish webrequest logs to Kafka.
            class { 'role::cache::varnish::kafka::webrequest':
                topic => 'webrequest_upload',
            }
        }
    }

    class bits inherits role::cache::varnish::1layer {

        if $::realm == 'production' {
            include role::cache::ssl::sni
        }

        class { 'lvs::realserver':
            realserver_ips => $lvs::configuration::lvs_service_ips[$::realm]['bits'][$::site],
        }

        $common_cluster_options = {
            'test_hostname'      => 'test.wikipedia.org',
            'enable_geoiplookup' => true,
        }

        $default_backend = 'backend'
        $varnish_directors = {
            1 => {
                'backend' => $::role::cache::configuration::backends[$::realm]['bits_appservers'][$::mw_primary],
                'test_wikipedia' => $::role::cache::configuration::backends[$::realm]['test_appservers'][$::mw_primary],
            },
            2 => {
                'backend' => sort(flatten(values($role::cache::configuration::backends[$::realm]['bits'])))
            }
        }

        $probe = $cluster_tier ? {
            1       => 'bits',
            default => 'varnish',
        }
        case $::realm {
            'labs': {
                $realm_cluster_options = {
                    'top_domain'  => 'beta.wmflabs.org',
                    'bits_domain' => 'bits.beta.wmflabs.org',
                    'do_gzip'     => true,
                }
            }
            default: {
                $realm_cluster_options = {}
            }
        }
        $cluster_options = merge($common_cluster_options, $realm_cluster_options)

        $memory_storage_size = 2

        system::role { 'role::cache::bits':
            description => 'bits Varnish cache server',
        }

        require geoip
        require geoip::dev # for VCL compilation using libGeoIP

        include standard
        include nrpe

        varnish::instance { 'bits':
            name            => '',
            vcl             => 'bits',
            port            => 80,
            admin_port      => 6082,
            storage         => "-s malloc,${memory_storage_size}G",
            directors       => $varnish_directors[$cluster_tier],
            director_type   => 'random',
            vcl_config      => {
                'default_backend' => $default_backend,
                'retry503'        => 4,
                'retry5xx'        => 1,
                'cache4xx'        => '1m',
                'cluster_tier'    => $cluster_tier,
                'layer'           => 'frontend',
                'ssl_proxies'     => $wikimedia_networks,
            },
            backend_options => {
                'port'                  => 80,
                'connect_timeout'       => '5s',
                'first_byte_timeout'    => '35s',
                'between_bytes_timeout' => '4s',
                'max_connections'       => 10000,
                'probe'                 => $probe,
            },
            cluster_options => $cluster_options,
        }

        include role::cache::varnish::logging::eventlistener
        # Include a varnishkafka instance that will produce
        # eventlogging events to Kafka.
        include role::cache::varnish::kafka::eventlogging

        # ToDo: Remove production conditional once this works
        # is verified to work in labs.
        if $::realm == 'production' {
            # Install a varnishkafka producer to send
            # varnish webrequest logs to Kafka.
            class { 'role::cache::varnish::kafka::webrequest':
                topic        => 'webrequest_bits',
                varnish_name => $::hostname,
                varnish_svc_name => 'varnish',
            }

            include role::cache::varnish::kafka::statsv
        }
    }

    class mobile inherits role::cache::varnish::2layer {
        $memory_storage_size = floor((0.125 * $::memorysize_mb / 1024.0) + 0.5) # 1/8 of total mem

        if $::realm == 'production' {
            include role::cache::ssl::sni
        }

        class { 'lvs::realserver':
            realserver_ips => $lvs::configuration::lvs_service_ips[$::realm]['mobile'][$::site],
        }

        system::role { 'role::cache::mobile':
            description => 'mobile Varnish cache server',
        }

        include standard
        include nrpe

        require geoip
        require geoip::dev # for VCL compilation using libGeoIP

        $varnish_be_directors = {
            1 => {
                'backend'           => $role::cache::configuration::backends[$::realm]['appservers'][$::mw_primary],
                'api'               => $role::cache::configuration::backends[$::realm]['api'][$::mw_primary],
                'test_wikipedia'    => $role::cache::configuration::backends[$::realm]['test_appservers'][$::mw_primary],
            },
            2 => {
                'eqiad' => $role::cache::configuration::active_nodes[$::realm]['mobile']['eqiad'],
            }
        }

        if $cluster_tier == 1 {
            $director_retries = 2
        } else {
            $director_retries = $backend_weight * 4
        }

        varnish::setup_filesystem{ $storage_partitions:
            before => Varnish::Instance['mobile-backend']
        }

        class { 'varnish::htcppurger':
            varnish_instances => [ '127.0.0.1:80', '127.0.0.1:3128' ],
        }

        if $::role::cache::configuration::has_ganglia {
            include varnish::monitoring::ganglia::vhtcpd
        }

        case $::realm {
            'production': {
                $cluster_options = {
                    'enable_geoiplookup' => true,
                }
            }
            'labs': {
                $cluster_options = {
                    'enable_geoiplookup' => true,
                    'enable_esi'         => true,
                }
            }
        }

        $zero_site = $::realm ? {
            'production' => 'https://zero.wikimedia.org',
            'labs'       => 'http://zero.wikimedia.beta.wmflabs.org',
        }

        class { 'varnish::zero_update':
            site     => $zero_site,
            auth_src => 'puppet:///private/misc/zerofetcher.auth',
        }

        $storage_conf = $::realm ? {
            'production' => "-s main1=persistent,/srv/sda3/varnish.main1,${storage_size_main}G,$mma0 -s main2=persistent,/srv/sdb3/varnish.main2,${storage_size_main}G,$mma1",
            'labs'      => "-s main1=persistent,/srv/vdb/varnish.main1,${storage_size_main}G,$mma0 -s main2=persistent,/srv/vdb/varnish.main2,${storage_size_main}G,$mma1",
        }

        $runtime_param = $::site ? {
            # 'esams' => ["prefer_ipv6=on"],
            default  => [],
        }

        $director_type_cluster = $cluster_tier ? {
            1       => 'random',
            default => 'chash',
        }

        varnish::instance { 'mobile-backend':
            name               => '',
            vcl                => 'mobile-backend',
            port               => 3128,
            admin_port         => 6083,
            storage            => $storage_conf,
            runtime_parameters => $runtime_param,
            directors          => $varnish_be_directors[$cluster_tier],
            director_type      => $director_type_cluster,
            director_options   => {
                'retries' => $director_retries,
            },
            vcl_config         => {
                'default_backend'  => $default_backend,
                'retry503'         => 4,
                'retry5xx'         => 1,
                'purge_host_regex' => $purge_host_not_upload_re,
                'cluster_tier'     => $cluster_tier,
                'layer'            => 'backend',
                'ssl_proxies'      => $wikimedia_networks,
            },
            backend_options    => [
                {
                    'backend_match'   => '^mw1017\.eqiad\.wmnet$',
                    'max_connections' => 20,
                },
                {
                    'backend_match' => '^cp[0-9]+\.eqiad\.wmnet$',
                    'weight'        => $backend_weight,
                    'port'          => 3128,
                    'probe'         => 'varnish',
                },
                {
                    'port'                  => 80,
                    'connect_timeout'       => '5s',
                    'first_byte_timeout'    => '180s',
                    'between_bytes_timeout' => '4s',
                    'max_connections'       => 600,
                }],
            cluster_options    => $cluster_options,
            wikimedia_networks => $wikimedia_networks,
        }

        varnish::instance { 'mobile-frontend':
            name             => 'frontend',
            vcl              => 'mobile-frontend',
            extra_vcl        => ['zero'],
            port             => 80,
            admin_port       => 6082,
            storage          => "-s malloc,${memory_storage_size}G",
            directors        => {
                'backend' => $::role::cache::configuration::active_nodes[$::realm]['mobile'][$::site],
            },
            director_options => {
                'retries' => $backend_weight * size($::role::cache::configuration::active_nodes[$::realm]['mobile'][$::site]),
            },
            director_type    => 'chash',
            vcl_config       => {
                'retry5xx'         => 0,
                'purge_host_regex' => $purge_host_not_upload_re,
                'cluster_tier'     => $cluster_tier,
                'layer'            => 'frontend',
                'ssl_proxies'      => $wikimedia_networks,
            },
            backend_options  => [
            {
                'port'                  => 3128,
                'weight'                => $backend_weight,
                'connect_timeout'       => '5s',
                'first_byte_timeout'    => '185s',
                'between_bytes_timeout' => '2s',
                'max_connections'       => 100000,
                'probe'                 => 'varnish',
            }],
            cluster_options  => $cluster_options,
        }

        # varnish::logging to be removed once
        # udp2log kafka consumer is implemented and deployed.
        include role::cache::varnish::logging

        # ToDo: Remove production conditional once this works
        # is verified to work in labs.
        if $::realm == 'production' {
            # Install a varnishkafka producer to send
            # varnish webrequest logs to Kafka.
            class { 'role::cache::varnish::kafka::webrequest':
                topic => 'webrequest_mobile',
            }
        }
    }

    class ssl::parsoid {
        # Explicitly not adding wmf CA since it is not needed for now
        include role::protoproxy::ssl::common

        localssl { 'unified':
            certname       => 'uni.wikimedia.org',
            default_server => true,
        }
        localssl { 'wikimedia.org':
            certname       => 'sni.wikimedia.org',
            server_name    => 'wikimedia.org',
            server_aliases => ['*.wikimedia.org'],
        }
        localssl { 'm.wikimedia.org':
            certname       => 'sni.m.wikimedia.org',
            server_name    => 'm.wikimedia.org',
            server_aliases => ['*.m.wikimedia.org'],
        }
    }

    class parsoid inherits role::cache::varnish::2layer {

        if ( $::realm == 'production' ) {
            include role::cache::ssl::parsoid
            class { 'lvs::realserver':
                realserver_ips => $lvs::configuration::lvs_service_ips[$::realm]['parsoidcache'][$::site],
            }
        }

        system::role { 'role::cache::parsoid':
            description => 'Parsoid Varnish cache server',
        }

        include standard
        include nrpe

        $storage_partitions = $::realm ? {
            'production' => ['sda3', 'sdb3'],
            'labs'       => ['vdb'],
        }
        varnish::setup_filesystem{ $storage_partitions:
            before => Varnish::Instance['parsoid-backend'],
        }

        # No HTCP daemon for Parsoid; the MediaWiki extension sends PURGE requests itself
        #class { "varnish::htcppurger": varnish_instances => [ "localhost:80", "localhost:3128" ] }

        $storage_conf = $::realm ? {
            'production' => "-s main1=persistent,/srv/sda3/varnish.main1,${storage_size_main}G,$mma0 -s main2=persistent,/srv/sdb3/varnish.main2,${storage_size_main}G,$mma1",
            'labs' => "-s main1=persistent,/srv/vdb/varnish.main1,${storage_size_main}G,$mma0 -s main2=persistent,/srv/vdb/varnish.main2,${storage_size_main}G,$mma1",
        }

        varnish::instance { 'parsoid-backend':
            name             => '',
            vcl              => 'parsoid-backend',
            extra_vcl        => ['parsoid-common'],
            port             => 3128,
            admin_port       => 6083,
            storage          => $storage_conf,
            directors        => {
                'backend'          => $::role::cache::configuration::backends[$::realm]['parsoid'][$::mw_primary],
                'cxserver_backend' => $::role::cache::configuration::active_nodes[$::realm]['cxserver'][$::site],
                'citoid_backend'   => $::role::cache::configuration::active_nodes[$::realm]['citoid'][$::site],
                'restbase_backend' => $::role::cache::configuration::active_nodes[$::realm]['restbase'][$::site],
            },
            director_options => {
                'retries' => 2,
            },
            vcl_config       => {
                'retry5xx'    => 1,
                'ssl_proxies' => $wikimedia_networks,
            },
            backend_options  => [
                {
                    'backend_match'         => '^cxserver',
                    'port'                  => 8080,
                    'probe'                 => false,
                },
                {
                    'backend_match'         => '^citoid',
                    'port'                  => 1970,
                    'probe'                 => false,
                },
                {
                    'backend_match'         => '^restbase',
                    'port'                  => 7231,
                    'probe'                 => false, # TODO: Need probe here
                },
                {
                    'port'                  => 8000,
                    'connect_timeout'       => '5s',
                    'first_byte_timeout'    => '5m',
                    'between_bytes_timeout' => '20s',
                    'max_connections'       => 10000,
                }],
        }

        varnish::instance { 'parsoid-frontend':
            name             => 'frontend',
            vcl              => 'parsoid-frontend',
            extra_vcl        => ['parsoid-common'],
            port             => 80,
            admin_port       => 6082,
            directors        => {
                'backend'          => $::role::cache::configuration::active_nodes[$::realm]['parsoid'][$::site],
                'cxserver_backend' => $::role::cache::configuration::active_nodes[$::realm]['cxserver'][$::site],
                'citoid_backend'   => $::role::cache::configuration::active_nodes[$::realm]['citoid'][$::site],
                'restbase_backend' => $::role::cache::configuration::active_nodes[$::realm]['restbase'][$::site],
            },
            director_type    => 'chash',
            director_options => {
                'retries' => $backend_weight * size($::role::cache::configuration::active_nodes[$::realm]['parsoid'][$::site]),
            },
            vcl_config       => {
                'retry5xx'    => 0,
                'ssl_proxies' => $wikimedia_networks,
            },
            backend_options  => [
                {
                    'backend_match'         => '^cxserver',
                    'port'                  => 8080,
                    'probe'                 => false,
                },
                {
                    'backend_match'         => '^citoid',
                    'port'                  => 1970,
                    'probe'                 => false,
                },
                {
                    'backend_match'         => '^restbase',
                    'port'                  => 7231,
                    'probe'                 => false, # TODO: Need probe here
                },
                {
                'port'                  => 3128,
                'weight'                => $backend_weight,
                'connect_timeout'       => '5s',
                'first_byte_timeout'    => '6m',
                'between_bytes_timeout' => '20s',
                'max_connections'       => 100000,
                'probe'                 => 'varnish',
            }],
        }
    }

    class misc inherits role::cache::varnish::1layer {

        class { 'lvs::realserver':
            realserver_ips => $lvs::configuration::lvs_service_ips[$::realm]['misc_web'][$::site],
        }

        system::role { 'role::cache::misc':
            description => 'misc Varnish cache server'
        }

        include standard
        include nrpe
        include role::cache::ssl::misc

        $memory_storage_size = 8

        varnish::instance { 'misc':
            name            => '',
            vcl             => 'misc',
            port            => 80,
            admin_port      => 6082,
            storage         => "-s malloc,${memory_storage_size}G",
            vcl_config      => {
                'retry503'        => 4,
                'retry5xx'        => 1,
                'cache4xx'        => '1m',
                'layer'           => 'frontend',
                'ssl_proxies'     => $wikimedia_networks,
                'default_backend' => 'antimony',    # FIXME
                'allowed_methods' => '^(GET|HEAD|POST|PURGE|PUT)$',
            },
            backends        => [
                'antimony.wikimedia.org',
                'caesium.eqiad.wmnet',
                'californium.wikimedia.org',
                'dataset1001.wikimedia.org',
                'gallium.wikimedia.org',  # CI server
                'ytterbium.wikimedia.org', # Gerrit
                'graphite1001.eqiad.wmnet',
                'zirconium.wikimedia.org',
                'ruthenium.eqiad.wmnet', # parsoid rt test server
                'logstash1001.eqiad.wmnet',
                'logstash1002.eqiad.wmnet',
                'logstash1003.eqiad.wmnet',
                'netmon1001.wikimedia.org', # servermon
                'iridium.eqiad.wmnet', # main phab
                'terbium.eqiad.wmnet', # public_html
                'neon.wikimedia.org', # monitoring tools (icinga et al)
                'magnesium.wikimedia.org', # RT and racktables
                'stat1001.eqiad.wmnet', # metrics and metrics-api
                'palladium.eqiad.wmnet',
                'analytics1027.eqiad.wmnet', # Hue (Hadoop GUI)
                'analytics1001.eqiad.wmnet', # Hadoop Yarn ResourceManager GUI
            ],
            backend_options => [
            {
                'backend_match' => '^(antimony|ytterbium)',
                'port'          => 8080,
            },
            {
                'backend_match' => '^(ruthenium)',
                'port'          => 8001,
            },
            {
                'backend_match' => '^logstash',
                'probe'         => 'logstash',
            },
            {
                # hue serves requests on port 8888
                'backend_match' => '^analytics1027',
                'port'          => 8888,
            },
            {
                # Yarn ResourceManager UI serves requests on port 8088
                'backend_match' => '^analytics1001',
                'port'          => 8088,
            },
            {
                'port'                  => 80,
                'connect_timeout'       => '5s',
                'first_byte_timeout'    => '35s',
                'between_bytes_timeout' => '4s',
                'max_connections'       => 100,
            }],
            directors       => {
                'logstash' => [
                    'logstash1001.eqiad.wmnet',
                    'logstash1002.eqiad.wmnet',
                    'logstash1003.eqiad.wmnet',
                ]
            },
        }

        # ToDo: Remove production conditional once this works
        # is verified to work in labs.
        if $::realm == 'production' {
            # Install a varnishkafka producer to send
            # varnish webrequest logs to Kafka.
            class { 'role::cache::varnish::kafka::webrequest':
                topic => 'webrequest_misc',
                varnish_name => $::hostname,
                varnish_svc_name => 'varnish',
            }
        }
    }
}
