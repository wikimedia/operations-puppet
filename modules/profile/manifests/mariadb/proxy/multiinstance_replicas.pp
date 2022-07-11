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
    # Generate a hash of default standby servers for each section, which is the
    # "other" replica type.
    $standby_type = $replica_type ? {
        'web'       => 'analytics',
        'analytics' => 'web',
    }
    $base_section_servers = $replica_sections.reduce({}) |$memo, $section|{
        $backend_pql = @("PQL")
        facts[certname, value] {
            name = 'ipaddress' and
            resources { type = 'Class' and title = 'Role::Wmcs::Db::Wikireplicas::${replica_type.capitalize}_multiinstance' } and
            resources { type = 'Profile::Mariadb::Section' and title = '${section}' }
        }
        | PQL
        $standby_pql = @("PQL")
        facts[certname, value] {
            name = 'ipaddress' and
            resources { type = 'Class' and title = 'Role::Wmcs::Db::Wikireplicas::${standby_type.capitalize}_multiinstance' } and
            resources { type = 'Profile::Mariadb::Section' and title = '${section}' }
        }
        | PQL
        $backend_servers = Hash(wmflib::puppetdb_query($backend_pql).map |$value| {
            [$value['certname'], { 'ipaddress' => $value['value'] }]
        })
        $standby_servers = Hash(wmflib::puppetdb_query($standby_pql).map |$value| {
            [$value['certname'], { 'ipaddress' => $value['value'], 'standby' => true }]
        })
        $memo + { $section => deep_merge($backend_servers, $standby_servers) }
    }.filter |$section| { !$section[1].empty }

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
        nrpe_command => '/usr/local/lib/nagios/plugins/check_haproxy --check=failover',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/HAProxy',
    }
}
