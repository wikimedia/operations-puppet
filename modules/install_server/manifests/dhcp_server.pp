# @summary This class installs isc-dhcp-server and configures it
# @param ensure_service indicate if the service should be stopped or running
# @param a hash of managment networks

class install_server::dhcp_server (
    Stdlib::Ensure::Service                  $ensure_service = 'running',
    Hash[String, Array[Stdlib::IP::Address]] $mgmt_networks  = {},
    Hash[Wmflib::Sites, Stdlib::IP::Address] $tftp_servers   = {},
){

    ensure_packages(['isc-dhcp-server'])

    file { '/etc/dhcp':
        ensure => directory,
        mode   => '0444',
    }

    file { '/etc/dhcp/dhcpd.conf':
        ensure  => file,
        mode    => '0444',
        content => template('install_server/dhcp/dhcpd.conf.erb'),
        notify  => Service['isc-dhcp-server'],
    }

    # This is the general path of proxies for the automation include system.
    wmflib::dir::mkdir_p('/etc/dhcp/automation/proxies', {'purge' => true, 'recurse' => true})

    # Files with the entries managed by the automation Cookbooks (reimage) that generates
    # DHCP snippets based on DHCP Option 82 for physical hosts and MAC address based snippets
    # for Ganeti VMs.
    # Those two files are included in the main dhcpd.conf script and Puppet should not manage
    # their content, just create them if not present and fix their permissions.
    # Their content is generated by the dhcpincludes script.
    file { ['/etc/dhcp/automation/proxies/ttyS0-115200.conf',
            '/etc/dhcp/automation/proxies/ttyS1-115200.conf']:
        ensure  => file,
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        require => Package['isc-dhcp-server'],
    }

    # Those directories will be populated by the automation via cookbook with DHCP snippets
    file { ['/etc/dhcp/automation/ttyS0-115200/',
            '/etc/dhcp/automation/ttyS1-115200/']:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    # Generate include proxies for each management network for automation.
    file { '/etc/dhcp/automation.conf':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      content => template('install_server/automation.conf.erb'),
      notify  => Service['isc-dhcp-server'],
    }

    $mgmt_networks.keys.each | $netname | {
      file { "/etc/dhcp/automation/proxies/mgmt-${netname}.conf":
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444'
      }

      # Those directories will be populated by the automation via cookbook with DHCP snippets
      file { "/etc/dhcp/automation/mgmt-${netname}/":
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
      }
    }

    # DHCP configuration include compiler
    file { '/usr/local/sbin/dhcpincludes':
      ensure => present,
      owner  => 'root',
      group  => 'root',
      mode   => '0555',
      source => 'puppet:///modules/install_server/dhcpincludes.py'
    }

    # Configuration file for DHCP configuration include compiler
    # depends on $mgmt_networks variable above.
    file { '/etc/dhcp/dhcpincludes.yaml':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      content => template('install_server/dhcpincludes.yaml.erb')
    }

    file_line { 'dhcpd_interfaces':
        ensure  => present,
        path    => '/etc/default/isc-dhcp-server',
        line    => "INTERFACESv4=\"${facts['interface_primary']}\"  # Managed by puppet",
        match   => "INTERFACESv4=\"\"",
        require => Package['isc-dhcp-server'],
        notify  => Service['isc-dhcp-server'],
    }

    service { 'isc-dhcp-server':
        ensure    => $ensure_service,
        require   => Package['isc-dhcp-server'],
        subscribe => File['/etc/dhcp'],
    }
}
