# SPDX-License-Identifier: Apache-2.0
# == Class zookeeper::server
# Configures a zookeeper server.
# This requires that zookeeper is installed
# And that the current nodes fqdn is an entry in the
# $::zookeeper::hosts array.
#
# == Parameters
# $jmx_port             - JMX port.    Set this to false if you don't want to expose JMX.
# $java_opts            - JAVA_OPTS optional argument to pass to the JVM.
# $cleanup_script       - Full path of the cleanup script to execute.
#                         Default: /usr/share/zookeeper/bin/zkCleanup.sh
# $cleanup_script_args  - Arguments to pass to the script (or the shell)
#                         Default: '-n 10 > /dev/null'
# $cleanup_timer_deploy - If true it installs a daily systemd timer job that runs
#                         the cleanup_script with the provided arguments.
#                         Default: true

class zookeeper::server(
    $jmx_port             = 9998,
    $java_opts            = undef,
    $cleanup_script       = '/usr/share/zookeeper/bin/zkCleanup.sh',
    $cleanup_script_args  = '-n 10',
    $cleanup_timer_deploy = true,
    $default_template     = 'profile/zookeeper/zookeeper.default.erb',
    $log4j_template       = 'profile/zookeeper/log4j.properties.erb',
    $java_home            = undef,
) {
    # need zookeeper common package and config.
    Class['zookeeper'] -> Class['zookeeper::server']

    # Install zookeeper server package
    ensure_packages('zookeeperd')

    file { '/etc/default/zookeeper':
        content => template($default_template),
        require => Package['zookeeperd'],
    }

    file { '/etc/zookeeper/conf/log4j.properties':
        content => template($log4j_template),
        require => Package['zookeeperd'],
    }

    file { $::zookeeper::data_dir:
        ensure => 'directory',
        owner  => 'zookeeper',
        group  => 'zookeeper',
        mode   => '0755',
    }

    # Get this host's $myid from the $fqdn in the $zookeeper_hosts hash.
    $myid = $::zookeeper::hosts[$::fqdn]
    file { '/etc/zookeeper/conf/myid':
        content => $myid,
    }
    file { "${::zookeeper::data_dir}/myid":
        ensure => 'link',
        target => '/etc/zookeeper/conf/myid',
    }

    if debian::codename::eq('bookworm') {
        # Add log4j backend to slf4j to make log4j.properties work
        # See also https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1025012
        file_line { 'zookeeper-log4j-classpath':
            ensure   => present,
            path     => '/etc/zookeeper/conf/environment',
            line     => 'CLASSPATH="/etc/zookeeper/conf:/usr/share/java/zookeeper.jar:/usr/share/java/slf4j-log4j12.jar:/usr/share/java/log4j-1.2.jar"',
            match    => '^CLASSPATH=',
            multiple => false,
        }
    }

    service { 'zookeeper':
        ensure     => running,
        require    => [
            Package['zookeeperd'],
            File[ $::zookeeper::data_dir],
            File["${::zookeeper::data_dir}/myid"],
            File['/etc/default/zookeeper'],
            File['/etc/zookeeper/conf/zoo.cfg'],
            File['/etc/zookeeper/conf/myid'],
            File['/etc/zookeeper/conf/log4j.properties'],
        ],
        hasrestart => true,
        hasstatus  => true,
    }

    $cleanup_timer_ensure = $cleanup_timer_deploy ? {
        true    => 'present',
        default => 'absent',
    }

    systemd::timer::job { 'zookeeper-cleanup':
        ensure      => $cleanup_timer_ensure,
        description => 'Regular jobs for running the cleanup script',
        user        => 'zookeeper',
        command     => "${cleanup_script} ${cleanup_script_args}",
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* 0:10:00'},
        require     => Service['zookeeper'],
    }
}
