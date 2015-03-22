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
        $ipoct = $ganglia_clusters[$cluster]['id']
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
            $data_sources = {
                'Video scalers eqiad'            => 'tmh1001.eqiad.wmnet tmh1002.eqiad.wmnet',
                'Image scalers eqiad'            => 'mw1153.eqiad.wmnet mw1154.eqiad.wmnet',
                'API application servers eqiad'  => 'mw1114.eqiad.wmnet mw1115.eqiad.wmnet',
                'Application servers eqaid'      => 'mw1054.eqiad.wmnet mw1055.eqiad.wmnet',
                'Application servers codfw'      => 'install2001.wikimedia.org:10660',
                'Jobrunners eqiad'               => 'mw1001.eqiad.wmnet mw1002.eqiad.wmnet',
                'Jobrunners codfw'               => 'install2001.wikimedia.org:10680 mw2001.codfw.wmnet mw2080.codfw.wmnet',
                'MySQL'                          => 'db1050.eqiad.wmnet',
                'PDF servers eqiad'              => 'ocg1001.eqiad.wmnet',
                'Fundraising eqiad'              => 'pay-lvs1001.frack.eqiad.wmnet pay-lvs1002.frack.eqiad.wmnet',
                'Virtualization cluster eqiad'   => 'labnet1001.eqiad.wmnet virt1000.wikimedia.org',
                'Labs NFS cluster eqiad'         => 'labstore1001.eqiad.wmnet labstore1003.eqiad.wmnet',
                'MySQL eqiad'                    => 'dbstore1001.eqiad.wmnet dbstore1002.eqiad.wmnet',
                'LVS loadbalancers eqiad'        => 'lvs1001.wikimedia.org lvs1002.wikimedia.org',
                'LVS loadbalancers codfw'        => 'install2001.wikimedia.org:10651 lvs2001.codfw.wmnet lvs2002.codfw.wmnet',
                'Miscellaneous eqiad'            => 'carbon.wikimedia.org bast1001.wikimedia.org',
                'Miscellaneous codfw'            => 'install2001.wikimedia.org:10657',
                'Mobile caches eqiad'            => 'cp1046.eqiad.wmnet cp1047.eqiad.wmnet',
                'Mobile caches esams'            => 'hooft.esams.wikimedia.org:11677',
                'Bits caches eqiad'              => 'cp1056.eqiad.wmnet cp1057.eqiad.wmnet',
                'Upload caches eqiad'            => 'cp1048.eqiad.wmnet cp1061.eqiad.wmnet',
                'Swift eqiad'                    => 'ms-fe1001.eqiad.wmnet ms-fe1002.eqiad.wmnet',
                'Swift esams'                    => 'hooft.esams.wikimedia.org:11676',
                'Swift codfw'                    => 'install2001.wikimedia.org:10676',
                'Bits caches esams'              => 'hooft.esams.wikimedia.org:11670 cp3019.esams.wmnet cp3020.esams.wmnet',
                'LVS loadbalancers esams'        => 'hooft.esams.wikimedia.org:11651 lvs3001.esams.wmnet lvs3002.esams.wmnet',
                'Miscellaneous esams'            => 'hooft.esams.wikimedia.org:11657',
                'Analytics cluster eqiad'        => 'analytics1009.eqiad.wmnet analytics1010.eqiad.wmnet analytics1014.eqiad.wmnet',
                'Memcached eqiad'                => 'mc1001.eqiad.wmnet mc1002.eqiad.wmnet',
                'Text caches esams'              => 'hooft.esams.wikimedia.org:11669',
                'Upload caches esams'            => 'hooft.esams.wikimedia.org:11671 cp3003.esams.wmnet cp3004.esams.wmnet',
                'Parsoid eqiad'                  => 'wtp1001.eqiad.wmnet wtp1002.eqiad.wmnet',
                'Parsoid Varnish eqiad'          => 'cp1045.eqiad.wmnet cp1058.eqiad.wmnet',
                'Redis eqiad'                    => 'rdb1001.eqiad.wmnet rdb1002.eqiad.wmnet',
                'Text caches eqiad'              => 'cp1052.eqiad.wmnet cp1053.eqiad.wmnet',
                'Misc Web caches eqiad'          => 'cp1043.eqiad.wmnet cp1044.eqiad.wmnet',
                'LVS loadbalancers ulsfo'        => 'lvs4001.ulsfo.wmnet lvs4003.ulsfo.wmnet',
                'Bits caches ulsfo'              => 'cp4001.ulsfo.wmnet cp4003.ulsfo.wmnet',
                'Upload caches ulsfo'            => 'cp4005.ulsfo.wmnet cp4013.ulsfo.wmnet',
                'Mobile caches ulsfo'            => 'cp4011.ulsfo.wmnet cp4019.ulsfo.wmnet',
                'Text caches ulsfo'              => 'cp4008.ulsfo.wmnet cp4016.ulsfo.wmnet',
                'Elasticsearch eqiad'            => 'elastic1001.eqiad.wmnet elastic1007.eqiad.wmnet elastic1013.eqiad.wmnet',
                'Logstash eqiad'                 => 'logstash1001.eqiad.wmnet logstash1003.eqiad.wmnet',
                'RCStream eqiad'                 => 'rcs1001.eqiad.wmnet',
                'Analytics Kafka cluster eqiad'  => 'analytics1012.eqiad.wmnet analytics1018.eqiad.wmnet analytics1022.eqiad.wmnet',
                'Service Cluster A eqiad'        => 'sca1001.eqiad.wmnet sca1002.eqiad.wmnet',
                'Corp OIT LDAP mirror eqiad'     => 'plutonium.wikimedia.org',
                'Corp OIT LDAP mirror codfw'     => 'pollux.wikimedia.org',
            }
            $rra_sizes = '"RRA:AVERAGE:0.5:1:360" "RRA:AVERAGE:0.5:24:245" "RRA:AVERAGE:0.5:168:241" "RRA:AVERAGE:0.5:672:241" "RRA:AVERAGE:0.5:5760:371"'
            $rrd_rootdir = '/mnt/ganglia_tmp/rrds.pmtpa'
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
