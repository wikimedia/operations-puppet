# vim: set ts=4 et sw=4:
# ganglia.pp
#
# Parameters:
#  - $deaf:         Is the gmond process an aggregator
#  - $cname:            Cluster's name
#  - $location:         Machine's location
#  - $mcast_address:        Multicast "cluster" to join and send data on
#  - $authority_url:        URL used by gmond and gmetad
#  - $gridname:         Grid name used by gmetad
#  - $data_sources:     Hash of datasources used by gmetad (production only)
#  - $rra_sizes:        Round-robin archives sizes used by gmetad
#  - $rrd_rootdir:      Directory to store round-robin dbs used by gmetad
#  - $ganglia_servername:   Server name used by apache
#  - $ganglia_serveralias:  Server alias(es) used by apache
#  - $ganglia_webdir:       Path of web directory used by apache


class ganglia {

    # FIXME: remove after the ganglia module migration
    if (hiera('ganglia_class', 'new') == 'new') {

        include ganglia_new::monitor
        # FIXME: ugly, but without it bad things happen with check_ganglia
        $cname = $ganglia_new::monitor::cname
    }
    else {
        notice("Ganglia disabled here")
    }
}

# == Class ganglia::collector::config
# Ganglia gmetad config.  This class does not start
# gmetad.  Include ganglia::collector instead if you want to do that.
class ganglia::collector::config {
    package { 'gmetad':
        ensure => present,
    }

    $gridname = 'Wikimedia'
    $authority_url = 'http://ganglia.wikimedia.org'
    case $::hostname {
        # netmon1001 runs gmetad to get varnish data into torrus
        # unlike other servers, netmon1001 uses the default rrd_rootdir
        /^netmon1001$/: {
            $data_sources = {
                'Upload caches eqiad' => 'cp1048.eqiad.wmnet cp1061.eqiad.wmnet'
            }
            $rra_sizes = '"RRA:AVERAGE:0:1:4032" "RRA:AVERAGE:0.17:6:2016" "RRA:MAX:0.17:6:2016" "RRA:AVERAGE:0.042:288:732" "RRA:MAX:0.042:288:732"'
        }
        default: {
            fail("ganglia::collector is deprecated and only applied to netmon1001")
        }
    }

    file { "/etc/ganglia/gmetad.conf":
        ensure  => present,
        require => Package['gmetad'],
        content => template('ganglia/gmetad.conf.erb'),
        mode    => '0444',
    }
}

# == Class ganglia::collector
# This class inherits ganglia::collector::config
# to install gmetad.conf, and then ensures that
# gmetad is running.
class ganglia::collector inherits ganglia::collector::config {
    system::role { 'ganglia::collector': description => 'Ganglia gmetad aggregator' }

    service { 'gmetad':
        ensure    => running,
        require   => File["/etc/ganglia/gmetad.conf"],
        subscribe => File["/etc/ganglia/gmetad.conf"],
        hasstatus => false,
    }
}

# == Class: ganglia::aggregator
# for the machine class which listens on multicast and
# collects all the ganglia information from other sources
class ganglia::aggregator {
    # This overrides the default ganglia-monitor script
    # with one that starts up multiple instances of gmond
    file { '/etc/init.d/ganglia-monitor-aggrs':
        ensure  => present,
        source  => 'puppet:///files/ganglia/ganglia-monitor',
        mode    => '0555',
        require => Package['ganglia-monitor'],
    }
    service { 'ganglia-monitor-aggrs':
        ensure  => running,
        require => File['/etc/init.d/ganglia-monitor-aggrs'],
        enable  => true,
    }
}


# == Define ganglia::plugin::python
#
# Installs a Ganglia python plugin
#
# == Parameters:
#
# $plugins - the plugin name (ex: 'diskstat'), will install the Python file
# located in files/ganglia/plugins/${name}.py and expand the template from
# templates/ganglia/plugins/${name}.pyconf.erb.
# Defaults to $title as a convenience.
#
# $opts - optional hash which can be used in the template.  The
# defaults are hardcoded in the templates. Defaults to {}.
#
# == Examples:
#
# ganglia::plugin::python {'diskstat': }
#
# ganglia::plugin::python {'diskstat': opts => { 'devices' => ['sda', 'sdb'] }}
#
define ganglia::plugin::python( $plugin = $title, $opts = {} ) {
    file { "/usr/lib/ganglia/python_modules/${plugin}.py":
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => "puppet:///files/ganglia/plugins/${plugin}.py",
        notify => Service['ganglia-monitor'],
    }
    file { "/etc/ganglia/conf.d/${plugin}.pyconf":
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("ganglia/plugins/${plugin}.pyconf.erb"),
        notify  => Service['ganglia-monitor'],
    }
}
