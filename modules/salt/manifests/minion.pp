# == Class: salt::minion
#
# Provisions a Salt minion.
#
# === Parameters
#
# [*master*]
#   Sets the location of the salt master server. May be a string or
#   an array (for multi-master setups).
#
# [*master_finger*]
#   Fingerprint of the master public key to double verify the master
#   is valid. Find the fingerprint by running 'salt-key -F master' on
#   the salt master.
#
# [*id*]
#   Explicitly declare the ID for this minion to use.
#   Defaults to the value of $::fqdn.
#
# [*grains*]
#   An optional hash of custom static grains for this minion.
#
# === Examples
#
#   class { '::salt::minion':
#     master          => 'saltmaster.eqiad.wmnet',
#     master_finger   => 'a0:ce:17:67:fb:1e:07:da:c7:5f:45:27:d7:f3:11:d0'
#     grains          => {
#       cluster => $::cluster,
#     },
#   }
#
class salt::minion(
    $master,
    $master_finger,
    $id        = $::fqdn,
    $grains    = {},
) {
    $config = {
        id            => $id,
        master        => $master,
        master_finger => $master_finger,
        grains        => $grains,
        dns_check     => false,
    }

    # our config file must be in place before
    # package installation, so that the deb postinst
    # step which automatically starts the minion
    # will start it with the correct settings
    package { 'salt-minion':
        ensure  => present,
        require => File['/etc/salt/minion'],
    }

    service { 'salt-minion':
        ensure    => running,
        provider  => 'upstart',
        require   => Package['salt-minion'],
    }

    file { '/etc/init/salt-minion.override':
        ensure => absent,
        notify => Service['salt-minion'],
    }

    file { '/etc/salt':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/salt/minion':
        content => ordered_yaml($config),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['salt-minion'],
        require => File['/etc/salt'],
    }

    file { '/usr/local/sbin/grain-ensure':
        source  => 'puppet:///modules/salt/grain-ensure.py',
        owner   => 'root',
        group   => 'root',
        mode    => '0544',
        require => Package['salt-minion'],
    }
}
