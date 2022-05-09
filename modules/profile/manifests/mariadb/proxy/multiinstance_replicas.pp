# load balancing between several replica dbs on several instances!
class profile::mariadb::proxy::multiinstance_replicas(
    Optional[Hash[String,Hash]]     $section_overrides = lookup('profile::mariadb::proxy::multiinstance_replicas::section_overrides', {default_value => undef}),
    Hash[String,Stdlib::Port]       $section_ports     = lookup('profile::mariadb::section_ports'),
    Enum['analytics', 'web']        $replica_type      = lookup('profile::mariadb::proxy::multiinstance_replicas::replica_type'),
    ) {

    # This template is for stretch/HA1.7, may not work on earlier/later versions
    $replicas_template = 'multi-db-replicas.cfg.erb'

    # Generate a hash of valid backend servers for each section from puppetdb
    # The intent here is to define instances *on the db servers only*
    # because defining them all by hand for both haproxy servers seems like toil
    $replica_sections = ['s1','s2','s3','s4','s5','s6','s7','s8']
    $default_backend_servers = $replica_sections.reduce({}) |$memo, $section|{
        $memo + {$section =>  query_facts(
                    "Class['role::wmcs::db::wikireplicas::${replica_type}_multiinstance'] and Profile::Mariadb::Section[${section}]",
                    ['fqdn', 'ipaddress']
                )}
    }

    # Generate a hash of default standby servers for each section, which is the
    # "other" replica type.
    $standby_type = $replica_type ? {
        'web'       => 'analytics',
        'analytics' => 'web',
    }
    $base_standby_servers = $replica_sections.reduce({}) |$memo, $section|{
        $memo + {$section =>  query_facts(
                    "Class['role::wmcs::db::wikireplicas::${standby_type}_multiinstance'] and Profile::Mariadb::Section[${section}]",
                    ['fqdn', 'ipaddress']
                )}
    }

    # Keep Puppet Catalog Compiler happy. No puppetdb
    $scrubbed_standbys = $base_standby_servers.filter |$section|{
        !$section[1].empty
    }
    # Inserting a hash key into an existing nested hash in puppet is interesting
    $standby_servers = $scrubbed_standbys.reduce({}) |$memo, $section|{
        $memo + {$section[0] => $section[1].reduce({}) |$x, $config| {
            $x + {$config[0] => $config[1] + {'standby' => true}}
            }
        }
    }

    # Keep Puppet Catalog Compiler happy. No puppetdb
    $scrubbed_servers = $default_backend_servers.filter |$section|{
        !$section[1].empty
    }

    $base_section_servers = deep_merge($scrubbed_servers, $standby_servers)

    # Merge $section_overrides to provide weights and depoolings
    # NOTE: Overrides an entire section config intentionally, not server by server
    if $section_overrides {
        $section_servers = $base_section_servers + $section_overrides
    } else {
        $section_servers = $base_section_servers
    }
    file { '/etc/haproxy/conf.d/multi-db-replicas.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("profile/mariadb/proxy/${replicas_template}"),
    }
    # Open the ports to the cloud only
    $replica_sections.each |$section| {
        ferm::service { "${section}-proxy-serv":
            proto  => 'tcp',
            port   => $section_ports[$section],
            srange => '$CLOUD_NETWORKS_PUBLIC',
        }
    }

    # Open the ports to pybal via prod networks as well
    $replica_sections.each |$section| {
        ferm::service { "${section}-pybal":
            proto  => 'tcp',
            port   => $section_ports[$section],
            srange => '$PRODUCTION_NETWORKS',
        }
    }
    nrpe::monitor_service { 'haproxy_failover':
        description  => 'haproxy failover',
        nrpe_command => '/usr/lib/nagios/plugins/check_haproxy --check=failover',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/HAProxy',
    }
}
