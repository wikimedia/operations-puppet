# SPDX-License-Identifier: Apache-2.0
# == Class: netconsole::client
# Configure netconsole to log kernel messages to a remote server.
# See https://www.kernel.org/doc/Documentation/networking/netconsole.txt
#

class netconsole::client (
    Wmflib::Ensure                    $ensure = present,
    Optional[String]                  $dev_name = undef,
    Optional[Stdlib::IP::Address::V4] $local_ip = undef,
    Optional[Stdlib::IP::Address::V4] $remote_ip = undef,
    Optional[Stdlib::MAC]             $remote_mac = undef,
) {
    kmod::module { 'netconsole':
        ensure => $ensure,
    }

    if $ensure == present {
        file { '/sys/kernel/config/netconsole/target1':
            ensure  => 'directory',
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            require => Kmod::Module['netconsole'],
        }

        # Parameters need to be set before enabling the module. Otherwise,
        # setting them fails with the following error: netconsole: target
        # (target1) is enabled, disable to update parameters. Set priority
        # accordingly.
        sysfs::parameters { 'netconsole-params':
            values   => {
                'kernel/config/netconsole/target1/dev_name'   => $dev_name,
                'kernel/config/netconsole/target1/local_ip'   => $local_ip,
                'kernel/config/netconsole/target1/remote_ip'  => $remote_ip,
                'kernel/config/netconsole/target1/remote_mac' => $remote_mac,
            },
            require  => File['/sys/kernel/config/netconsole/target1'],
            priority => 60,
        }

        sysfs::parameters { 'netconsole-enable':
            require  => Sysfs::Parameters['netconsole-params'],
            priority => 70,
            values   => {
                'kernel/config/netconsole/target1/enabled' => '1',
            }
        }
    } else {
        # netconsole needs to be disabled via sysfs before attempting module
        # removal
        sysfs::parameters { 'netconsole-enable':
            before   => Kmod::Module['netconsole'],
            priority => 70,
            values   => {
                'kernel/config/netconsole/target1/enabled' => '0',
            },
        }

        # The configuration directory needs to be removed after the target has
        # been disabled and before removing the kernel module.
        file { '/sys/kernel/config/netconsole/target1':
            ensure  => absent,
            require => Sysfs::Parameters['netconsole-enable'],
            before  => Kmod::Module['netconsole'],
            backup  => false,
            force   => true,
        }
    }
}
