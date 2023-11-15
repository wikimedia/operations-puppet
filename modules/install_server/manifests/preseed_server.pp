# Class: install_server::preseed_server
#
# This class populated preseeding server's configuration
#
# Parameters:
#
# Actions:
#       Populate preseeding configuration directory
#
# Requires:
#
# Sample Usage:
#   include install_server::preseed_server

class install_server::preseed_server (
  Hash[String[1], Install_server::Preseed_subnet::Config] $preseed_subnets = {},
  Hash[String[1], Array[Install_server::Preseed_host::Config]] $preseed_per_hostname = {},

) {
  file { '/srv/autoinstall':
    ensure  => directory,
    mode    => '0444',
    source  => 'puppet:///modules/install_server/autoinstall',
    recurse => true,
    purge   => true,
  }

  file { '/srv/autoinstall/subnets':
    ensure => directory,
    mode   => '0444',
  }

  $preseed_subnets.each |$subnet_name, $subnet_config| {
    file { "/srv/autoinstall/subnets/${subnet_name}.cfg":
      ensure  => file,
      mode    => '0444',
      content => template('install_server/autoinstall_subnet.cfg.erb'),
    }
  }

  $preseed_per_gateway = Hash(
    $preseed_subnets.map |$subnet_name, $subnet_config| {
      [$subnet_config['subnet_gateway'], "subnets/${subnet_name}.cfg"]
    }
  )
  file { '/srv/autoinstall/netboot.cfg':
    ensure  => file,
    mode    => '0444',
    content => template('install_server/netboot.cfg.erb'),
  }

  file { '/srv/autoinstall/preseed.cfg':
    ensure => link,
    target => '/srv/autoinstall/netboot.cfg',
  }
}
