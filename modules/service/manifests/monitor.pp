# A class to setup service based monitoring for all services, LVS based or not
class service::monitor() {
    # Services in "monitoring_setup" state will be configured but won't page.
    # Services in "production" state will be fully configured.
    $enabled_states = ['monitoring_setup', 'production']
    $monitored_services = wmflib::service::fetch().filter |$n, $data| {
        ('monitoring' in $data and $data['state'] in $enabled_states)
    }
    # First let's declare all the hosts.
    $hosts = $monitored_services.map |$n, $data | {
        # TODO: use get() in puppet 6.x
        $contact_group = pick($data['monitoring']['contact_group'], 'admins')

        $data['monitoring']['sites'].map |$sitename, $host| {
            $hostname = $host['hostname']
            $data['ip'][$sitename].map |$k, $ip| {
                # TODO: only make critical hosts in production state.
                $host_params = {
                    'ip_address'    => $ip,
                    'contact_group' => $contact_group,
                    'critical'      => true,
                    'lvs'           => has_key($data, 'lvs'),
                }
                if $ip =~ Stdlib::IP::Address::V4 {
                    { $hostname => $host_params}
                }
                else {
                    {"${hostname}_ipv6" => $host_params}
                }
            }
        }
    }
    .flatten()
    .reduce({})|$memo,$el| {$memo.merge($el)} # TODO: improve this. Right now it can coalesce values erratically between different services.

    # NOTE: We skip creating hosts for non LVS based services, but rather assume
    # they are created via other means
    $hosts.filter |$hostname, $params| { $params['lvs'] == true }.each |$hostname, $params| {
        @monitoring::host { $hostname:
            ip_address    => $params['ip_address'],
            contact_group => $params['contact_group'],
            group         => 'lvs',
            critical      => $params['critical']
        }
    }

    # Now that all monitoring hosts have been declared, let's declare the services.
    $monitored_services.each |$n, $data| {
        $is_lvs = has_key($data, 'lvs')
        $monitoring = $data['monitoring']
        $critical = $data['state'] ? {
            'monitoring_setup' => false,
            default            => $monitoring['critical']
        }
        $monitoring['sites'].each |$sitename, $host| {
            $hostname = $host['hostname']
            $service_title = "${hostname}_${n}"
            $service_title_v6 = "${service_title}_v6"
            $port = $data['port']
            if $is_lvs {
                $protocol = pick($data['lvs']['protocol'], 'tcp')
                $descr_prefix = 'LVS '
            } else {
                $protocol = 'tcp'  # NOTE: We are making an assumption here
                $descr_prefix = ''
            }
            # Ensure the description matches the actual site we're setting the alert up for, 
            # not the one evaluated by $::site. See T283762
            $description = regsubst($data['description'], "svc\\.${::site}\\.wmnet", "svc.${sitename}.wmnet")
            $check_description = "${descr_prefix}${n} ${sitename} port ${port}/${protocol} - ${description}"
            # Let's set a default notes_url if one does not exist
            $notes_url = pick($monitoring['notes_url'], 'https://wikitech.wikimedia.org/wiki/LVS#Diagnosing_problems')

            # Add ipv4 monitoring if present
            if $hostname in $hosts {
                @monitoring::service { $service_title:
                    host          => $hostname,
                    group         => 'lvs',
                    description   => "${check_description} IPv4",
                    check_command => $monitoring['check_command'],
                    critical      => $critical,
                    contact_group => $monitoring['contact_group'],
                    notes_url     => $notes_url,
                }
            }
            # Add ipv6 monitoring if present
            if "${hostname}_ipv6" in $hosts {
                @monitoring::service { $service_title_v6:
                    host          => "${hostname}_ipv6",
                    group         => 'lvs',
                    description   => "${check_description} IPv6",
                    check_command => $monitoring['check_command'],
                    critical      => $critical,
                    contact_group => $monitoring['contact_group'],
                    notes_url     => $notes_url,
                }
            }
        }
    }
}
