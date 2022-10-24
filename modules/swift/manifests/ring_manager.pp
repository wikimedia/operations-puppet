# SPDX-License-Identifier: Apache-2.0
# == Class swift::ring_manager
#
# @summary Installs the swift_ring_manager tool for automatic
# management of swift rings Alongside the configuration file for the
# relevant cluster, a Systemd timer to run swift_ring_manager, and
# rsync server to provide rings to the puppetmasters
#
# @param [String] swift_cluster
#     Name of the swift cluster
# @param [Wmflib::Ensure] ensure
#     present/absent to install/remove checkout/config/timer
# @param [Array[String]] puppetmasters
#     Array of servers to allow rsync from
class swift::ring_manager (
    String           $swift_cluster,
    Wmflib::Ensure   $ensure = 'absent',
    Array[String]    $puppetmasters = [],
    Stdlib::Unixpath $install_dir = '/srv/deployment/swift_ring_manager',
    Optional[Stdlib::Unixpath] $ring_dir = '/var/cache/swift_rings',
) {

    #pre-bullseye, we want python to run swift_ring_manager, & python-yaml
    #bullseye and later, use python3 and python3-yaml
    $python = debian::codename::lt('bullseye') ? {
        true  => 'python',
        false => 'python3',
    }
    $yaml_package = "${python}-yaml"
    ensure_packages($yaml_package)

    # install_dir is managed by git::clone
    wmflib::dir::mkdir_p([$install_dir.dirname(), $ring_dir])

    $git_ensure = $ensure ? {
        absent  => 'absent',
        present => 'latest',
    }
    git::clone { 'swift_ring_manager':
        ensure    => $git_ensure,
        directory => $install_dir,
        origin    => 'https://gitlab.wikimedia.org/repos/data_persistence/swift-ring',
        branch    => 'main',
        }

    file { '/etc/swift/hosts.yaml':
        ensure => $ensure,
        source => "puppet:///modules/swift/${swift_cluster}_hosts.yaml",
    }

    #Wrapper that runs swift_ring_manager.py with the correct python
    #This means that we can use syslog matching in process name too
    file { '/usr/local/bin/swift_ring_manager':
        ensure  => file,
        mode    => '0555',
        content => "#!/bin/sh\n/usr/bin/${python} ${install_dir}/swift_ring_manager.py \"$@\"",
    }

    systemd::timer::job { 'swift_ring_manager':
        ensure        => $ensure,
        command       => "/usr/local/bin/swift_ring_manager -o ${ring_dir} --doit --syslog",
        interval      => {'start' => 'OnCalendar', 'interval' => '*:10:00'},
        logfile_name  => 'swift_ring_manager.log',
        logfile_owner => 'swift',
        user          => 'root',
        description   => 'Swift ring manager',
    }

    rsync::server::module { 'swiftrings':
        ensure         => $ensure,
        read_only      => 'yes',
        hosts_allow    => $puppetmasters,
        auto_ferm      => true,
        auto_ferm_ipv6 => true,
        chroot         => false,
        path           => $ring_dir,
    }
}
