# vim: set ts=4 et sw=4:
# ganglia.pp
#
# Parameters:
#  - $deaf:         Is the gmond process an aggregator
#  - $cname:            Cluster / Cloud 's name
#  - $location:         Machine's location
#  - $mcast_address:        Multicast "cluster" to join and send data on (production only)
#  - $gmetad_host:      Hostname or IP of gmetad server used by gmond (labs only)
#  - $authority_url:        URL used by gmond and gmetad
#  - $gridname:         Grid name used by gmetad
#  - $data_sources:     Hash of datasources used by gmetad (production only)
#  - $rra_sizes:        Round-robin archives sizes used by gmetad
#  - $rrd_rootdir:      Directory to store round-robin dbs used by gmetad
#  - $gmetad_conf:      gmetad conf filename (ends in '.labsstub' for labs)
#  - $ganglia_servername:   Server name used by apache
#  - $ganglia_serveralias:  Server alias(es) used by apache
#  - $ganglia_webdir:       Path of web directory used by apache


class ganglia {

    # FIXME: remove after the ganglia module migration
    if $::realm == 'labs' or ($::hostname in ['netmon1001'] or $::site == 'esams' or $::site == 'codfw') {
        $ganglia_cluster = $::realm ? {
            labs    => $::instanceproject,
            default => $cluster
        }
        class { 'ganglia_new::monitor':
            cluster => $ganglia_cluster,
        }
    } else {
            if ! $::cluster {
                $cluster = 'misc'
            }
            # aggregator should not be deaf (they should listen)
            # ganglia_aggregator for production are defined in site.pp;
            # for labs, 'deaf = "no"' is defined in gmond.conf.labsstub
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
        $ganglia_clusters = {
            'decommissioned' => {
                'name'      => 'Decommissioned servers',
                'ip_oct'    => '1' },
            'lvs' => {
                'name'      => 'LVS loadbalancers',
                'ip_oct'    => '2' },
            'search'    =>  {
                'name'      => 'Search',
                'ip_oct'    => '4' },
            'mysql'     =>  {
                'name'      => 'MySQL',
                'ip_oct'    => '5' },
            'misc'      =>  {
                'name'      => 'Miscellaneous',
                'ip_oct'    => '8' },
            'appserver' =>  {
                'name'      => 'Application servers',
                'ip_oct'    => '11' },
            'imagescaler'   =>  {
                'name'      => 'Image scalers',
                'ip_oct'    => '12' },
            'api_appserver' =>  {
                'name'      => 'API application servers',
                'ip_oct'    => '13' },
            'pdf'       =>  {
                'name'      => 'PDF servers',
                'ip_oct'    => '15' },
            'cache_text'    => {
                'name'      => 'Text caches',
                'ip_oct'    => '20' },
            'cache_bits'    => {
                'name'      => 'Bits caches',
                'ip_oct'    => '21' },
            'cache_upload'  => {
                'name'      => 'Upload caches',
                'ip_oct'    => '22' },
            'payments'  => {
                'name'      => 'Fundraiser payments',
                'ip_oct'    => '23' },
            'swift' => {
                'name'      => 'Swift',
                'ip_oct'    => '27' },
            'cache_mobile'  => {
                'name'      => 'Mobile caches',
                'ip_oct'    => '28' },
            'virt'  => {
                'name'      => 'Virtualization cluster',
                'ip_oct'    => '29' },
            'jobrunner' =>  {
                'name'      => 'Jobrunners',
                'ip_oct'    => '31' },
            'analytics'     => {
                'name'      => 'Analytics cluster',
                'ip_oct'    => '32' },
            'memcached'     => {
                'name'      => 'Memcached',
                'ip_oct'    => '33' },
            'videoscaler'       => {
                'name'      => 'Video scalers',
                'ip_oct'    => '34' },
            'fundraising'   => {
                'name'      => 'Fundraising',
                'ip_oct'    => '35' },
            'ceph'          => { # Not used anymore
                'name'      => 'Ceph',
                'ip_oct'    => '36' },
            'parsoid'       => {
                'name'      => 'Parsoid',
                'ip_oct'    => '37' },
            'cache_parsoid' => {
                'name'      => 'Parsoid Varnish',
                'ip_oct'    => '38' },
            'redis'         => {
                'name'      => 'Redis',
                'ip_oct'    => '39' },
            'labsnfs'   => {
                'name'      => 'Labs NFS cluster',
                'ip_oct'    => '40' },
            'cache_misc'    => {
                'name'      => 'Misc Web caching cluster',
                'ip_oct'    => '41' },
            'elasticsearch' => {
                'name'      => 'Elasticsearch cluster',
                'ip_oct'    => '42' },
            'logstash'      => {
                'name'      => 'Logstash cluster',
                'ip_oct'    => '43' },
            'rcstream'      => {
                'name'      => 'RCStream cluster',
                'ip_oct'    => '44' },
            'analytics_kafka' => {
                'name'      => 'Analytics Kafka cluster',
                'ip_oct'    => '45' },
            'sca'           => {
                'name'      => 'Service Cluster A',
                'ip_oct'    => '46' },
            'openldap_corp_mirror'           => {
                'name'      => 'Corp OIT LDAP mirror',
                'ip_oct'    => '47' },
        }
        # NOTE: Do *not* add new clusters *per site* anymore,
        # the site name will automatically be appended now,
        # and a different IP prefix will be used.

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

    if $::realm == 'labs' {
        $gridname = 'wmflabs'
        # for labs, just generate a stub gmetad configuration without data_source lines
        $gmetad_conf = 'gmetad.conf.labsstub'
        $authority_url = 'http://ganglia.wmflabs.org'
        $rra_sizes = '"RRA:AVERAGE:0.5:1:360" "RRA:AVERAGE:0.5:24:245" "RRA:AVERAGE:0.5:168:241" "RRA:AVERAGE:0.5:672:241" "RRA:AVERAGE:0.5:5760:371"'
        $rrd_rootdir = '/mnt/ganglia_tmp/rrds.pmtpa'
    } else {
        $gridname = 'Wikimedia'
        $gmetad_conf = 'gmetad.conf'
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
            # neon needs gmetad config
            /^neon$/: {
                $data_sources = {
                    'Miscellaneous eqiad'            => 'carbon.wikimedia.org ms1004.eqiad.wmnet',
                    'Miscellaneous codfw'            => 'install2001.wikimedia.org',
                    'Analytics cluster eqiad'        => 'analytics1009.eqiad.wmnet analytics1010.eqiad.wmnet analytics1014.eqiad.wmnet',
                    'Mobile caches eqiad'            => 'cp1046.eqiad.wmnet cp1047.eqiad.wmnet',
                    'Mobile caches esams'            => 'hooft.esams.wikimedia.org:11677',
                    'Mobile caches ulsfo'            => 'cp4011.ulsfo.wmnet cp4019.ulsfo.wmnet',
                    'Analytics Kafka cluster eqiad'  => 'analytics1012.eqiad.wmnet analytics1018.eqiad.wmnet analytics1022.eqiad.wmnet',
                }
                $rra_sizes = '"RRA:AVERAGE:0.5:1:360" "RRA:AVERAGE:0.5:24:245" "RRA:AVERAGE:    0.5:168:241" "RRA:AVERAGE:0.5:672:241" "RRA:AVERAGE:0.5:5760:371"'
                }
            default: {
                $data_sources = {
                    'Video scalers eqiad'            => 'tmh1001.eqiad.wmnet tmh1002.eqiad.wmnet',
                    'Image scalers eqiad'            => 'mw1153.eqiad.wmnet mw1154.eqiad.wmnet',
                    'API application servers eqiad'  => 'mw1114.eqiad.wmnet mw1115.eqiad.wmnet',
                    'Application servers eqaid'      => 'mw1054.eqiad.wmnet mw1055.eqiad.wmnet',
                    'Jobrunners eqiad'               => 'mw1001.eqiad.wmnet mw1002.eqiad.wmnet',
                    'MySQL'                          => 'db1050.eqiad.wmnet',
                    'PDF servers eqiad'              => 'ocg1001.eqiad.wmnet',
                    'Fundraising eqiad'              => 'pay-lvs1001.frack.eqiad.wmnet pay-lvs1002.frack.eqiad.wmnet',
                    'Virtualization cluster eqiad'   => 'labnet1001.eqiad.wmnet virt1000.wikimedia.org',
                    'Labs NFS cluster eqiad'         => 'labstore1001.eqiad.wmnet labstore1003.eqiad.wmnet',
                    'MySQL eqiad'                    => 'db1053.eqiad.wmnet db1054.eqiad.wmnet db1057.eqiad.wmnet',
                    'LVS loadbalancers eqiad'        => 'lvs1001.wikimedia.org lvs1002.wikimedia.org',
                    'LVS loadbalancers codfw'        => 'install2001.wikimedia.org:10651 lvs2001.codfw.wmnet lvs2002.codfw.wmnet',
                    'Miscellaneous eqiad'            => 'carbon.wikimedia.org ms1004.eqiad.wmnet',
                    'Miscellaneous codfw'            => 'install2001.wikimedia.org:10657',
                    'Mobile caches eqiad'            => 'cp1046.eqiad.wmnet cp1047.eqiad.wmnet',
                    'Mobile caches esams'            => 'hooft.esams.wikimedia.org:11677',
                    'Bits caches eqiad'              => 'cp1056.eqiad.wmnet cp1057.eqiad.wmnet',
                    'Upload caches eqiad'            => 'cp1048.eqiad.wmnet cp1061.eqiad.wmnet',
                    'Swift eqiad'                    => 'ms-fe1001.eqiad.wmnet ms-fe1002.eqiad.wmnet',
                    'Swift esams'                    => 'hooft.esams.wikimedia.org:11676',
                    'Swift codfw'                    => 'install2001.wikimedia.org:10676',
                    'Search eqiad'                   => 'search1001.eqiad.wmnet search1002.eqiad.wmnet',
                    'Bits caches esams'              => 'hooft.esams.wikimedia.org:11670 cp3019.esams.wikimedia.org cp3020.esams.wikimedia.org',
                    'LVS loadbalancers esams'        => 'hooft.esams.wikimedia.org:11651 lvs3001.esams.wmnet lvs3002.esams.wmnet',
                    'Miscellaneous esams'            => 'hooft.esams.wikimedia.org:11657',
                    'Analytics cluster eqiad'        => 'analytics1009.eqiad.wmnet analytics1010.eqiad.wmnet analytics1014.eqiad.wmnet',
                    'Memcached eqiad'                => 'mc1001.eqiad.wmnet mc1002.eqiad.wmnet',
                    'Text caches esams'              => 'hooft.esams.wikimedia.org:11669',
                    'Upload caches esams'            => 'hooft.esams.wikimedia.org:11671 cp3003.esams.wikimedia.org cp3004.esams.wikimedia.org',
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
    }

    file { "/etc/ganglia/${gmetad_conf}":
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

    # for labs, gmond.conf and gmetad.conf are generated every 4 hours by a
    # cron job
    if $::realm == 'labs' {
        file { '/etc/ganglia/gmond.conf.labsstub':
            ensure => present,
            source => 'puppet:///files/ganglia/gmond.conf.labsstub',
            mode   => '0444',
        }

        file { '/usr/local/sbin/generate-ganglia-conf.py':
            ensure => present,
            source => 'puppet:///files/ganglia/generate-ganglia-conf.py',
            mode   => '0755',
        }

        cron { 'generate-ganglia-conf':
            ensure      => present,
            command     => '/usr/local/sbin/generate-ganglia-conf.py',
            require     => Package['gmetad'],
            user        => 'root',
            hour        => [0, 4, 8, 12, 16, 20],
            minute      => 30,
            environment => 'PATH=$PATH:/sbin',
        }

        # log gmetad messages to /var/log/ganglia.log
        rsyslog::conf { 'ganglia':
            source   => 'puppet:///files/ganglia/rsyslog.d/30-ganglia.conf',
            priority => 30,
        }

        file { '/etc/logrotate.d/ganglia':
            ensure => present,
            source => 'puppet:///files/logrotate/ganglia',
            mode   => '0444',
        }
    }

    service { 'gmetad':
        ensure    => running,
        require   => File["/etc/ganglia/${gmetad_conf}"],
        subscribe => File["/etc/ganglia/${gmetad_conf}"],
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

class ganglia::web {
# Class for the ganglia frontend machine

    require ganglia::collector

    include ::apache
    include ::apache::mod::php5
    include ::apache::mod::ssl
    include ::apache::mod::rewrite

    ganglia::plugin::python { 'diskstat': }

    package { [ 'php5-gd',
                'php5-mysql',
                'rrdtool',
                'librrds-perl',
            ]:
        ensure => present,
    }

    # Monitoring
    monitoring::service { 'ganglia_http':
        description   => 'HTTP',
        check_command => 'check_http',
    }

    if $::realm == 'labs' {
        $ganglia_servername = 'ganglia.wmflabs.org'
        $ganglia_webdir = '/usr/share/ganglia-webfrontend'
        $ganglia_confdir = '/var/lib/ganglia/conf'
        $ganglia_dwoo = '/var/lib/ganglia/dwoo'
        $ganglia_dwoo_cache = "${ganglia_dwoo}/cache"
        $ganglia_dwoo_compiled = "${ganglia_dwoo}/compiled"

        file { [
            $ganglia_confdir,
            $ganglia_dwoo,
            $ganglia_dwoo_cache,
            $ganglia_dwoo_compiled,
        ]:
            ensure => directory,
            owner  => 'www-data',
            group  => 'root',
            mode   => '0775',
        }

        include ganglia::aggregator

        file { '/usr/share/ganglia-webfrontend/conf.php':
            ensure  => present,
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            source  => 'puppet:///files/ganglia/conf.php',
            require => Package['ganglia-webfrontend'],
        }
        file { '/usr/share/ganglia-webfrontend/conf_default.php':
            ensure => link,
            target => '/usr/share/ganglia-webfrontend/conf.php',
        }
        file { '/usr/share/ganglia-webfrontend/version.php':
            content => '<?php $GLOBALS["ganglia_version"] = "wmflabs";';
        }

    } else {
        # We are in production land
        $ganglia_servername = 'ganglia.wikimedia.org'

        package { 'ganglia-webfrontend':
            ensure => present,
        }
        $ganglia_webdir = '/usr/share/ganglia-webfrontend'
        $ganglia_confdir = '/var/lib/ganglia-web'
        file { '/etc/ganglia-webfrontend/conf.php':
            ensure  => present,
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            source  => 'puppet:///files/ganglia/conf_production.php',
            require => Package['ganglia-webfrontend'],
        }
        $ganglia_ssl_cert = '/etc/ssl/certs/ganglia.wikimedia.org.pem'
        $ganglia_ssl_key = '/etc/ssl/private/ganglia.wikimedia.org.key'

        $ssl_settings = ssl_ciphersuite('apache-2.2', 'compat')
        include role::backup::host
        backup::set { 'var-lib-ganglia': }
    }

    apache::site { $ganglia_servername:
        content => template("apache/sites/${ganglia_servername}.erb"),
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
