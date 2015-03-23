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
    if (hiera('ganglia_class') == 'new') {

        include ganglia_new::monitor
        # FIXME: ugly, but without it bad things happen with check_ganglia
        $cname = $ganglia_new::monitor::cname
    } else {
        $cluster = hiera('cluster', $cluster)
        # aggregator should not be deaf (they should listen)
        # ganglia_aggregator for production are defined in site.pp;
        if $ganglia_aggregator {
            $deaf = 'no'
        } else {
            $deaf = 'yes'
        }

        $authority_url = 'http://ganglia.wikimedia.org'

        $location = 'unspecified'

        $ip_prefix = $::site ? {
            'pmtpa' => '239.192.0',
            'eqiad' => '239.192.1',
            'codfw' => '239.192.2',
            'esams' => '239.192.20',
            'ulsfo' => '239.192.10'
        }

        $name_suffix = " ${::site}"

        # NOTE: Do *not* add new clusters *per site* anymore,
        # the site name will automatically be appended now,
        # and a different IP prefix will be used.
        $ganglia_clusters = hiera('ganglia_clusters')

        # gmond.conf template variables
        $ipoct = $ganglia_clusters[$cluster]['ip_oct']
        $mcast_address = "${ip_prefix}.${ipoct}"
        $clustername = $ganglia_clusters[$cluster][name]
        $cname = "${clustername}${name_suffix}"

        # Resource definitions
        file { '/etc/ganglia/gmond.conf':
            ensure  => present,
            require => Package['ganglia-monitor'],
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template('ganglia/gmond_template.erb'),
            notify  => Service['ganglia-monitor'],
        }

        if !defined(Package['ganglia-monitor']) {
            package { 'ganglia-monitor':
                ensure => present,
            }
        }

        file { [ '/etc/ganglia/conf.d', '/usr/lib/ganglia/python_modules' ]:
            ensure  => directory,
            require => Package['ganglia-monitor'],
        }

        service { 'ganglia-monitor':
            ensure    => running,
            require   => [
                File['/etc/ganglia/gmond.conf'],
                Package['ganglia-monitor']
            ],
            subscribe => File['/etc/ganglia/gmond.conf'],
            hasstatus => false,
            pattern   => 'gmond',
        }

        group { 'gmetric':
            ensure => present,
            name   => 'gmetric',
            system => true,
        }

        user { 'gmetric':
            home       => '/home/gmetric',
            shell      => '/bin/sh',
            managehome => true,
            system     => true,
        }
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

# == Class ganglia::logtailer
#
# The class pulls in everything necessary to get a ganglia-logtailer instance
# on a machine.
class ganglia::logtailer {
    package { 'ganglia-logtailer':
        ensure => latest,
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

# Copied from nagios::ganglia::monitor::enwiki
# Will run on terbium to use the local MediaWiki install so that we can use
# maintenance scripts recycling DB connections and taking a few secs, not mins
class misc::monitoring::jobqueue {

    cron { 'all_jobqueue_length':
        ensure  => present,
        command => "/usr/bin/gmetric --name='Global JobQueue length' --type=int32 --conf=/etc/ganglia/gmond.conf --value=$(/usr/local/bin/mwscript extensions/WikimediaMaintenance/getJobQueueLengths.php --totalonly | grep -oE '[0-9]+') > /dev/null 2>&1",
        user    => 'mwdeploy',
    }

    # duplicating the above job to experiment with gmetric's host spoofing so
    # as to gather these metrics in a fake host called "www.wikimedia.org"
    cron { 'all_jobqueue_length_spoofed':
        ensure  => present,
        command => "/usr/bin/gmetric --name='Global JobQueue length' --type=int32 --conf=/etc/ganglia/gmond.conf --spoof 'www.wikimedia.org:www.wikimedia.org' --value=$(/usr/local/bin/mwscript extensions/WikimediaMaintenance/getJobQueueLengths.php --totalonly | grep -oE '[0-9]+') > /dev/null 2>&1",
        user    => 'mwdeploy',
    }
}
