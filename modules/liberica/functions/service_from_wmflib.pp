# SPDX-License-Identifier: Apache-2.0
function liberica::service_from_wmflib(
    Hash[String, Wmflib::Service] $svcs,
    Wmflib::Sites $site,
) >> Hash[String, Liberica::Service] {

    $ret = $svcs.reduce({})|$svcs_memo, $svcs_value| {
        $svc_name = $svcs_value[0]
        $svc = $svcs_value[1]

        if 'bgp' in $svc['lvs'] and $svc['lvs']['bgp'] == false {
            fail('BGP is mandatory in liberica')
        }
        unless $svc['lvs']['scheduler'] == 'mh' {
            fail("scheduler ${svc['lvs']['scheduler']} not supported by liberica")
        }

        $protocol = $svc['lvs']['protocol'] ? {
            Liberica::Protocol => $svc['lvs']['protocol'],
            default            => 'tcp',
        }

        $forward_type = $site in $svc['lvs']['ipip_encapsulation']? {
            true  => 'tunnel',
            false => 'direct_route',
        }

        $healthchecks = $svc['lvs']['monitors']? {
            Hash[Enum['ProxyFetch', 'IdleConnection', 'UDP'], Hash] => $svc['lvs']['monitors'].reduce({})|$hcs_memo, $hcs_value| {
                $hc_type = $hcs_value[0]
                $hc_cfg = $hcs_value[1]

                if $hc_type == 'ProxyFetch' and !$hc_cfg['url'] {
                    fail('invalid ProxyFetch configuration')
                }

                # default values for healthcheck configuration settings
                $status_code = $hc_cfg['http_status'] ? {
                    Stdlib::Http::Status => $hc_cfg['http_status'],
                    default              => 200,
                }

                $http_check_timeout = $hc_cfg['timeout'] ? {
                    Integer => "${hc_cfg['timeout']}s",
                    default => '5s',
                }

                $http_check_period = $hc_cfg['interval'] ? {
                    Integer => "${hc_cfg['interval']}s",
                    default => '10s',
                }

                $idle_connection_timeout = $hc_cfg['timeout-clean-reconnect'] ? {
                    Integer => "${hc_cfg['timeout-clean-reconnect']}s",
                    default => '3s',
                }

                $hc = $hc_type? {
                    'ProxyFetch'     => $hc_cfg['url'].reduce({})|$url_memo, Stdlib::HTTPUrl $url| {
                        $hc_url = {
                            # this produces pretty long names for ProxyFetch healthchecks
                            "L7-${url}"  => {
                                type         => 'HTTPCheck',
                                url          => $url,
                                status_code  => $status_code,
                                timeout      => $http_check_timeout,
                                check_period => $http_check_period,
                            },
                        }
                        $url_memo + $hc_url
                    },
                    'IdleConnection' => {
                        'L4' => {
                            type             => 'IdleTCPConnectionCheck',
                            timeout          => $idle_connection_timeout,
                            check_period     => '300ms',
                            reconnect_period => '1s',
                        },
                    },
                    default          => fail("unsupported healthcheck type: ${hc_type}"),
                }
                $hcs_memo + $hc
            },
            default                                                 => {},
        }

        $lb_svcs = $svc['ip'][$site].values().reduce({})|$ip_memo, Stdlib::IP::Address $ip| {
            $name = $ip ? {
                Stdlib::IP::Address::V4::Nosubnet => "${svc_name}lb_${svc['port']}",
                Stdlib::IP::Address::V6::Nosubnet => "${svc_name}lb6_${svc['port']}",
            }
            $lb_svc = {
                $name => {
                    forward_type     => $forward_type,
                    depool_threshold => $svc['lvs']['depool_threshold'],
                    cluster          => $svc['lvs']['conftool']['cluster'],
                    service          => $svc['lvs']['conftool']['service'],
                    ip               => $ip,
                    port             => $svc['port'],
                    protocol         => $protocol,
                    healthchecks     => $healthchecks,
                },
            }
            $ip_memo + $lb_svc
        }
        $svcs_memo + $lb_svcs
    }
}
