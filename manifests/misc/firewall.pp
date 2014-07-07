class firewall::builder {

    package { ['fwconfigtool', 'python-argparse'] :
          ensure => latest,
    }
    file { '/var/lib/fwconfigtool':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/var/lib/fwconfigtool/machineports':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    # collect all fw definitions
    Exported_acl_rule <<| |>>

}

class firewall { 
    # for each inbound ACL create an exported file on the main server

    # This is the definition called from all service manifests, e.g.
    # open_port { "mail": port => 25 }

    define open_port(
        $port,
        $hostname  = $::hostname,
        $ip_address= $::ipaddress,
        $protocol  = 'tcp',
    ) {
        @@exported_acl_rule { $title:
            hostname   => $hostname,
            ip_address => $ip_address,
            protocol   => $protocol,
            port       => $port,
        }
    }

    define exported_acl_rule(
        $port,
        $hostname   = $::hostname,
        $ip_address = $::ipaddress,
        $protocol   = 'tcp',
    ) {
        file { "/var/lib/fwconfigtool/machineports/${ip_address}-${port}":
            ensure  => present,
            content => "${hostname},${ip_address},${protocol},${port}\n",
            owner   => 'root',
            group   => 'root',
            tag     => 'inboundacl',
        }
    }

}

class testcase1 {
    include firewall
    firewall::open_port { 'testbox':
        port => 80,
    }
    firewall::open_port { 'test2':
        port => 443,
    }
}

class testcase2 {
    include firewall
    firewall::inboundacl { 'test2':
        ip_address => '2.3.4.5',
        port       => 80,
    }
}
