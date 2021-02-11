# @summary This class installs isc-dhcp-server and configures it
# @param ensure_service indicate if the service should be stopped or running
# @param a hash of managment networks

class install_server::dhcp_server (
    Stdlib::Ensure::Service                  $ensure_service = 'running',
    Hash[String, Array[Stdlib::IP::Address]] $mgmt_networks = {}
){

    ensure_packages(['isc-dhcp-server'])

    file { '/etc/dhcp':
        ensure  => directory,
        recurse => true,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/install_server/dhcpd',
    }

    # This is the general path of proxies for the automation include system.
    wmflib::dir::mkdir_p('/etc/dhcp/automation/proxies/')

    # Files with the entries matching DHCP option 82, those are managed by the automation Cookbooks
    # and included in the dhcpd.conf file. Puppet should not manage those but create them empty if
    # not present and fix their permissionsnd if different.
    file { ['/etc/dhcp/opt82-entries.ttyS0-115200', '/etc/dhcp/opt82-entries.ttyS1-115200']:
        ensure  => file,
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        require => Package['isc-dhcp-server'],
    }

    file { ['/etc/dhcp/automation/opt82-entries.ttyS0-115200/', '/etc/dhcp/automation/opt82-entries.ttyS1-115200/']:
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
      content => template('install_server/automation.conf.erb')
    }

    $mgmt_networks.keys.each | $netname | {
      file { "/etc/dhcp/automation/proxies/proxy-mgmt.${netname}.conf":
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444'
      }

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

    # TODO: Fold this into modules/install/dhcpd once
    # all jessie-based install servers are replaced.
    if debian::codename::ge('buster') {
        file_line { 'dhcpd_interfaces':
          ensure  => present,
          path    => '/etc/default/isc-dhcp-server',
          line    => "INTERFACESv4=\"${facts['interface_primary']}\"  # Managed by puppet",
          match   => "INTERFACESv4=\"\"",
          require => Package['isc-dhcp-server'],
          notify  => Service['isc-dhcp-server'],
        }
    }

    service { 'isc-dhcp-server':
        ensure    => $ensure_service,
        require   => Package['isc-dhcp-server'],
        subscribe => File['/etc/dhcp'],
    }
}
