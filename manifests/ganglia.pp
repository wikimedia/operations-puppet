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
    if $::realm == "labs" or ($::hostname in ["manutius"] or $::site == "esams" or ($::site == "pmtpa" and $cluster in ["cache_bits"])) {
        class { "ganglia_new::monitor":
            cluster => $::realm ? {
                labs => $::instanceproject,
                default => $cluster
            }
        }
    } else {
        if $::hostname in $::decommissioned_servers {
            $cluster = "decommissioned"
            $deaf = "no"
        } else {
            if ! $::cluster {
                $cluster = "misc"
            }
            # aggregator should not be deaf (they should listen)
            # ganglia_aggregator for production are defined in site.pp;
            # for labs, 'deaf = "no"' is defined in gmond.conf.labsstub
            if $ganglia_aggregator {
                $deaf = "no"
            } else {
                $deaf = "yes"
            }
        }

        $authority_url = "http://ganglia.wikimedia.org"

        $location = "unspecified"

        $ip_prefix = $::site ? {
            "pmtpa" => "239.192.0",
            "eqiad" => "239.192.1",
            "esams" => "239.192.20",
            "ulsfo" => "239.192.10"
        }

        $name_suffix = " ${::site}"

        # NOTE: Do *not* add new clusters *per site* anymore,
        # the site name will automatically be appended now,
        # and a different IP prefix will be used.
        $ganglia_clusters = {
            "decommissioned" => {
                "name"      => "Decommissioned servers",
                "ip_oct"    => "1" },
            "lvs" => {
                "name"      => "LVS loadbalancers",
                "ip_oct"    => "2" },
            "search"    =>  {
                "name"      => "Search",
                "ip_oct"    => "4" },
            "mysql"     =>  {
                "name"      => "MySQL",
                "ip_oct"    => "5" },
            "misc"      =>  {
                "name"      => "Miscellaneous",
                "ip_oct"    => "8" },
            "appserver" =>  {
                "name"      => "Application servers",
                "ip_oct"    => "11" },
            "imagescaler"   =>  {
                "name"      => "Image scalers",
                "ip_oct"    => "12" },
            "api_appserver" =>  {
                "name"      => "API application servers",
                "ip_oct"    => "13" },
            "pdf"       =>  {
                "name"      => "PDF servers",
                "ip_oct"    => "15" },
            "cache_text"    => {
                "name"      => "Text caches",
                "ip_oct"    => "20" },
            "cache_bits"    => {
                "name"      => "Bits caches",
                "ip_oct"    => "21" },
            "cache_upload"  => {
                "name"      => "Upload caches",
                "ip_oct"    => "22" },
            "payments"  => {
                "name"      => "Fundraiser payments",
                "ip_oct"    => "23" },
            "bits_appserver"    => {
                "name"      => "Bits application servers",
                "ip_oct"    => "24" },
            "ssl"       => {
                "name"      => "SSL cluster",
                "ip_oct"    => "26" },
            "swift" => {
                "name"      => "Swift",
                "ip_oct"    => "27" },
            "cache_mobile"  => {
                "name"      => "Mobile caches",
                "ip_oct"    => "28" },
            "virt"  => {
                "name"      => "Virtualization cluster",
                "ip_oct"    => "29" },
            "gluster"   => {
                "name"      => "Glusterfs cluster",
                "ip_oct"    => "30" },
            "jobrunner" =>  {
                "name"      => "Jobrunners",
                "ip_oct"    => "31" },
            "analytics"     => {
                "name"      => "Analytics cluster",
                "ip_oct"    => "32" },
            "memcached"     => {
                "name"      => "Memcached",
                "ip_oct"    => "33" },
            "videoscaler"       => {
                "name"      => "Video scalers",
                "ip_oct"    => "34" },
            "fundraising"   => {
                "name"      => "Fundraising",
                "ip_oct"    => "35" },
            "ceph"          => {
                "name"      => "Ceph",
                "ip_oct"    => "36" },
            "parsoid"       => {
                "name"      => "Parsoid",
                "ip_oct"    => "37" },
            "cache_parsoid" => {
                "name"      => "Parsoid Varnish",
                "ip_oct"    => "38" },
            "redis"         => {
                "name"      => "Redis",
                "ip_oct"    => "39" },
            "labsnfs"   => {
                "name"      => "Labs NFS cluster",
                "ip_oct"    => "40" },
            'cache_misc'    => {
                'name'      => 'Misc Web caching cluster',
                'ip_oct'    => '41' },
            'elasticsearch' => {
                'name'      => 'Elasticsearch cluster',
                'ip_oct'    => '42' },
            'logstash'      => {
                'name'      => 'Logstash cluster',
                'ip_oct'    => '43' },
        }
        # NOTE: Do *not* add new clusters *per site* anymore,
        # the site name will automatically be appended now,
        # and a different IP prefix will be used.

        # gmond.conf template variables
        $ipoct = $ganglia_clusters[$cluster]["ip_oct"]
        $mcast_address = "${ip_prefix}.${ipoct}"
        $clustername = $ganglia_clusters[$cluster][name]
        $cname = "${clustername}${name_suffix}"

        if versioncmp($::lsbdistrelease, "9.10") >= 0 {
            $gmond = "ganglia-monitor"
        }
        else {
            $gmond = "gmond"
        }

        $gmondpath = $gmond ? {
            "ganglia-monitor"       => "/etc/ganglia/gmond.conf",
            default                 => "/etc/gmond.conf"
        }


        # Resource definitions
        file { "gmondconfig":
            require => Package[$gmond],
            name    => $gmondpath,
            owner   => "root",
            group   => "root",
            mode    => 0444,
            content => template("ganglia/gmond_template.erb"),
            notify  => Service['gmond'],
            ensure  => present
        }

        case $gmond {
            gmond: {
                package {
                    "gmond":
                        ensure => latest,
                        alias => "gmond-package";
                    "ganglia-monitor":
                        before => Package['gmond'],
                        ensure => purged;
                }
            }
            ganglia-monitor: {
                if !defined(Package["ganglia-monitor"]) {
                    package {
                        "gmond":
                            before => Package[ganglia-monitor],
                            ensure => purged;
                        "ganglia-monitor":
                            ensure => present,
                            alias => "gmond-package";
                    }
                }

                file { [ "/etc/ganglia/conf.d", "/usr/lib/ganglia/python_modules" ]:
                    require => Package[ganglia-monitor],
                    ensure => directory;
                }

                file { "/etc/gmond.conf":
                    ensure => absent;
                }
            }
        }

        service {
            "gmond":
                name        => $gmond,
                require     => [ File[gmondconfig], Package["gmond-package"] ],
                subscribe   => File[gmondconfig],
                hasstatus   => false,
                pattern     => "gmond",
                ensure      => running;
        }

        generic::systemuser { gmetric: name => "gmetric", home => "/home/gmetric", shell => "/bin/sh" }
    }

    # == Class ganglia::collector::config
    # Ganglia gmetad config.  This class does not start
    # gmetad.  Include ganglia::collector instead if you want to do that.
    class collector::config {
        package { "gmetad":
            ensure => present;
        }

        if $::realm == "labs" {
            $gridname = "wmflabs"
            # for labs, just generate a stub gmetad configuration without data_source lines
            $gmetad_conf = "gmetad.conf.labsstub"
            $authority_url = "http://ganglia.wmflabs.org"
            $rra_sizes = '"RRA:AVERAGE:0.5:1:360" "RRA:AVERAGE:0.5:24:245" "RRA:AVERAGE:0.5:168:241" "RRA:AVERAGE:0.5:672:241" "RRA:AVERAGE:0.5:5760:371"'
            $rrd_rootdir = "/mnt/ganglia_tmp/rrds.pmtpa"
        } else {
            $gridname = "Wikimedia"
            $gmetad_conf = "gmetad.conf"
            $authority_url = "http://ganglia.wikimedia.org"
            case $::hostname {
                # manutius runs gmetad to get varnish data into torrus
                # unlike other servers, manutius uses the default rrd_rootdir
                /^manutius$/: {
                    $data_sources = {
                        "Upload caches eqiad" => "cp1048.eqiad.wmnet cp1061.eqiad.wmnet"
                    }
                    $rra_sizes = '"RRA:AVERAGE:0:1:4032" "RRA:AVERAGE:0.17:6:2016" "RRA:MAX:0.17:6:2016" "RRA:AVERAGE:0.042:288:732" "RRA:MAX:0.042:288:732"'
                }
                # neon needs gmetad config for ganglios
                /^neon$/: {
                    $data_sources = {
                        "Miscellaneous"                  => "tarin.pmtpa.wmnet",
                        "Miscellaneous eqiad"            => "carbon.wikimedia.org ms1004.eqiad.wmnet",
                        "Analytics cluster eqiad"        => "analytics1009.eqiad.wmnet analytics1010.eqiad.wmnet analytics1014.eqiad.wmnet",
                        "Mobile caches eqiad"            => "cp1046.eqiad.wmnet cp1047.eqiad.wmnet",
                        "Mobile caches esams"            => "hooft.esams.wikimedia.org:11677",
                        "Mobile caches ulsfo"            => 'cp4011.ulsfo.wmnet cp4019.ulsfo.wmnet',
                    }
                    $rra_sizes = '"RRA:AVERAGE:0.5:1:360" "RRA:AVERAGE:0.5:24:245" "RRA:AVERAGE:    0.5:168:241" "RRA:AVERAGE:0.5:672:241" "RRA:AVERAGE:0.5:5760:371"'
                    }
                default: {
                    $data_sources = {
                        "Video scalers eqiad"            => "tmh1001.eqiad.wmnet tmh1002.eqiad.wmnet",
                        "Image scalers eqiad"            => "mw1153.eqiad.wmnet mw1154.eqiad.wmnet",
                        "API application servers eqiad"  => "mw1114.eqiad.wmnet mw1115.eqiad.wmnet",
                        "Application servers eqaid"      => "mw1017.eqiad.wmnet mw1018.eqiad.wmnet",
                        "Jobrunners eqiad"              => "mw1001.eqiad.wmnet mw1002.eqiad.wmnet",
                        "Bits application servers eqiad" => "mw1151.eqiad.wmnet mw1152.eqiad.wmnet",
                        "MySQL"                          => "db1050.eqiad.wmnet",
                        "PDF servers"                    => "pdf2.wikimedia.org pdf3.wikimedia.org",
                        "Miscellaneous"                  => "tarin.pmtpa.wmnet",
                        "Fundraising eqiad"              => "pay-lvs1001.frack.eqiad.wmnet pay-lvs1002.frack.eqiad.wmnet",
                        "SSL cluster esams"              => "hooft.esams.wikimedia.org:11675 ssl3001.esams.wikimedia.org ssl3002.esams.wikimedia.org",
                        "Swift pmtpa"                    => "ms-fe1.pmtpa.wmnet ms-fe2.pmtpa.wmnet",
                        "Virtualization cluster eqiad"   => "labnet1001.eqiad.wmnet virt1000.wikimedia.org",
                        "Virtualization cluster pmtpa"   => "virt5.pmtpa.wmnet virt0.wikimedia.org",
                        "Glusterfs cluster pmtpa"        => "labstore1.pmtpa.wmnet labstore2.pmtpa.wmnet",
                        "MySQL eqiad"                    => "db1056.eqiad.wmnet db1021.eqiad.wmnet",
                        "LVS loadbalancers eqiad"        => "lvs1001.wikimedia.org lvs1002.wikimedia.org",
                        "Miscellaneous eqiad"            => "carbon.wikimedia.org ms1004.eqiad.wmnet",
                        "Mobile caches eqiad"            => "cp1046.eqiad.wmnet cp1047.eqiad.wmnet",
                        "Mobile caches esams"            => "hooft.esams.wikimedia.org:11677",
                        "Bits caches eqiad"              => "cp1056.eqiad.wmnet cp1057.eqiad.wmnet",
                        "Upload caches eqiad"            => "cp1048.eqiad.wmnet cp1061.eqiad.wmnet",
                        "SSL cluster eqiad"              => "ssl1001.wikimedia.org ssl1002.wikimedia.org",
                        "Swift eqiad"                    => "ms-fe1001.eqiad.wmnet ms-fe1002.eqiad.wmnet",
                        "Search eqiad"                   => "search1001.eqiad.wmnet search1002.eqiad.wmnet",
                        "Bits caches esams"              => "hooft.esams.wikimedia.org:11670 cp3019.esams.wikimedia.org cp3020.esams.wikimedia.org",
                        "LVS loadbalancers esams"        => "hooft.esams.wikimedia.org:11651 amslvs1.esams.wikimedia.org amslvs2.esams.wikimedia.org",
                        "Miscellaneous esams"            => "hooft.esams.wikimedia.org:11657",
                        "Analytics cluster eqiad"        => "analytics1009.eqiad.wmnet analytics1010.eqiad.wmnet analytics1014.eqiad.wmnet",
                        "Memcached eqiad"                => "mc1001.eqiad.wmnet mc1002.eqiad.wmnet",
                        "Text caches esams"              => "hooft.esams.wikimedia.org:11669",
                        "Upload caches esams"            => "hooft.esams.wikimedia.org:11671 cp3003.esams.wikimedia.org cp3004.esams.wikimedia.org",
                        "Ceph cluster esams"             => "ms-be3001.esams.wikimedia.org ms-be3002.esams.wikimedia.org",
                        "Parsoid eqiad"                  => "wtp1001.eqiad.wmnet",
                        "Parsoid Varnish eqiad"          => "cp1045.eqiad.wmnet cp1058.eqiad.wmnet",
                        "Redis eqiad"                    => "rdb1001.eqiad.wmnet rdb1002.eqiad.wmnet",
                        "Labs NFS cluster pmtpa"         => "labstore3.pmtpa.wmnet labstore4.pmtpa.wmnet",
                        "Text caches eqiad"              => "cp1052.eqiad.wmnet cp1053.eqiad.wmnet",
                        'Misc Web caches eqiad'          => 'cp1043.eqiad.wmnet cp1044.eqiad.wmnet',
                        "LVS loadbalancers ulsfo"        => "lvs4001.ulsfo.wmnet lvs4003.ulsfo.wmnet",
                        "Bits caches ulsfo"              => 'cp4001.ulsfo.wmnet cp4003.ulsfo.wmnet',
                        "Upload caches ulsfo"            => 'cp4005.ulsfo.wmnet cp4013.ulsfo.wmnet',
                        "Mobile caches ulsfo"            => 'cp4011.ulsfo.wmnet cp4019.ulsfo.wmnet',
                        "Text caches ulsfo"              => 'cp4008.ulsfo.wmnet cp4016.ulsfo.wmnet',
                        "Elasticsearch eqiad"            => 'elastic1001.eqiad.wmnet elastic1007.eqiad.wmnet elastic1013.eqiad.wmnet',
                        "Logstash eqiad"                 => 'logstash1001.eqiad.wmnet logstash1003.eqiad.wmnet',

                    }
                    $rra_sizes = '"RRA:AVERAGE:0.5:1:360" "RRA:AVERAGE:0.5:24:245" "RRA:AVERAGE:0.5:168:241" "RRA:AVERAGE:0.5:672:241" "RRA:AVERAGE:0.5:5760:371"'
                    $rrd_rootdir = "/mnt/ganglia_tmp/rrds.pmtpa"
                }
            }
        }

        file { "/etc/ganglia/${gmetad_conf}":
            require => Package[gmetad],
            content => template("ganglia/gmetad.conf.erb"),
            mode => 0444,
            ensure  => present
        }
    }

    # == Class ganglia::collector
    # This class inherits ganglia::collector::config
    # to install gmetad.conf, and then ensures that
    # gmetad is running.
    class collector inherits ganglia::collector::config {
        system::role { "ganglia::collector": description => "Ganglia gmetad aggregator" }

        # for labs, gmond.conf and gmetad.conf are generated every 4 hours by a cron job
        if $::realm == "labs" {
            file { "/etc/ganglia/gmond.conf.labsstub":
                source => "puppet:///files/ganglia/gmond.conf.labsstub",
                mode => 0444,
                ensure => present;
            }

            file { "/usr/local/sbin/generate-ganglia-conf.py":
                source => "puppet:///files/ganglia/generate-ganglia-conf.py",
                mode => 0755,
                ensure => present;
            }

            cron { generate-ganglia-conf:
                command => "/usr/local/sbin/generate-ganglia-conf.py",
                require => Package[gmetad],
                user => root,
                hour => [0, 4, 8, 12, 16, 20],
                minute => 30,
                ensure => present,
                environment => 'PATH=$PATH:/sbin',
            }

            # log gmetad messages to /var/log/ganglia.log
            file { "/etc/rsyslog.d/30-ganglia.conf":
                source => "puppet:///files/ganglia/rsyslog.d/30-ganglia.conf",
                mode => 0444,
                ensure => present,
                notify => Service["rsyslog"];
            }

            file { "/etc/logrotate.d/ganglia":
                source => "puppet:///files/logrotate/ganglia",
                mode => 0444,
                ensure => present;
            }
        }

        service { "gmetad":
            require => File["/etc/ganglia/${gmetad_conf}"],
            subscribe => File["/etc/ganglia/${gmetad_conf}"],
            hasstatus => false,
            ensure => running;
        }
    }

    # Class: ganglia::aggregator
    # for the machine class which listens on multicast and
    # collects all the ganglia information from other sources
    class aggregator {
        # This overrides the default ganglia-monitor script
        # with one that starts up multiple instances of gmond
        file { "/etc/init.d/ganglia-monitor-aggrs":
            source => "puppet:///files/ganglia/ganglia-monitor",
            mode   => 0555,
            ensure => present,
            require => Package["ganglia-monitor"];
        }
        service { "ganglia-monitor-aggrs":
            require => File["/etc/init.d/ganglia-monitor-aggrs"],
            enable => true,
            ensure => running;
        }
    }
}

class ganglia::web {
# Class for the ganglia frontend machine

    require ganglia::collector,
        webserver::php5-gd,
        webserver::php5-mysql,
        subversion::client

    class {'webserver::php5': ssl => true; }

    if $::realm == "labs" {
        $ganglia_servername = "ganglia.wmflabs.org"
        $ganglia_serveralias = "aggregator1.pmtpa.wmflabs"
        $ganglia_webdir = "/usr/share/ganglia-webfrontend"
        $ganglia_confdir = "/var/lib/ganglia/conf"

        include ganglia::aggregator
    } else {
        $ganglia_servername = "ganglia.wikimedia.org"
        $ganglia_serveralias = "nickel.wikimedia.org ganglia3.wikimedia.org ganglia3-tip.wikimedia.org"
        # TODO(ssmollett): when switching to ganglia-webfrontend
        # package, use /usr/share/ganglia-webfrontend
        $ganglia_webdir = "/srv/org/wikimedia/ganglia-web-latest"
        $ganglia_confdir = "/srv/org/wikimedia/ganglia-web-conf"

        $ganglia_ssl_cert = "/etc/ssl/certs/ganglia.wikimedia.org.pem"
        $ganglia_ssl_key = "/etc/ssl/private/ganglia.wikimedia.org.key"
    }

    file {
        "/etc/apache2/sites-available/${ganglia_servername}":
            mode => 0444,
            owner => root,
            group => root,
            content => template("apache/sites/ganglia.wikimedia.org.erb"),
            ensure => present;
        "/usr/local/bin/restore-gmetad-rrds":
            mode => 0555,
            owner => root,
            group => root,
            source => "puppet:///files/ganglia/restore-gmetad-rrds",
            ensure => present;
        "/usr/local/bin/save-gmetad-rrds":
            mode => 0555,
            owner => root,
            group => root,
            source => "puppet:///files/ganglia/save-gmetad-rrds",
            ensure => present;
        "/etc/init.d/gmetad":
            mode => 0555,
            owner => root,
            group => root,
            source => "puppet:///files/ganglia/gmetad",
            ensure => present;
        "/var/lib/ganglia/rrds.pmtpa/":
            mode => 0755,
            owner => nobody,
            group => root,
            ensure => directory;
        "/etc/rc.local":
            mode => 0555,
            owner => root,
            group => root,
            source => "puppet:///files/ganglia/rc.local",
            ensure => present;
    }

    apache_site { ganglia: name => $ganglia_servername }
    apache_module { rewrite: name => "rewrite" }

    package {
        "librrds-perl":
            before => Package[rrdtool],
            ensure => latest;
        "rrdtool":
            ensure => latest,
    }

    # back up rrds every half hour
    cron { "save-rrds":
        command => "/usr/local/bin/save-gmetad-rrds",
        user => root,
        minute => [ 7, 37 ],
        ensure => present
    }

    # Mount /mnt/ganglia_tmp as tmpfs to avoid Linux flushing mlocked
    # shm memory to disk
    $ganglia_tmp_mountpoint = "/mnt/ganglia_tmp"

    file { "$ganglia_tmp_mountpoint":
        mode => 0755,
        owner => root,
        group => root,
        ensure => directory;
    }

    mount { "$ganglia_tmp_mountpoint":
        require => File["$ganglia_tmp_mountpoint"],
        device => "tmpfs",
        fstype => "tmpfs",
        options => "noauto,noatime,defaults,size=4000m",
        pass => 0,
        dump => 0,
        ensure => mounted;
    }

    file { "${ganglia_tmp_mountpoint}/rrds.pmtpa":
        require => Mount["$ganglia_tmp_mountpoint"],
        mode => 0755,
        owner => nobody,
        group => root,
        ensure => directory;
    }


    # TODO(ssmollett): install ganglia-webfrontend package in production,
    # using appropriate conf.php
    if $::realm == "labs" {
        package { "ganglia-webfrontend":
            ensure => latest;
        }

        file { "/usr/share/ganglia-webfrontend/conf.php":
            mode => 0444,
            owner => root,
            group => root,
            source => "puppet:///files/ganglia/conf.php",
            require => Package[ganglia-webfrontend],
            ensure => present;
        }
    }
}

class ganglia::logtailer {
    # this class pulls in everything necessary to get a ganglia-logtailer instance on a machine

    package { "ganglia-logtailer":
        ensure => latest;
    }
}


# == Define ganglia::view
# Defines a Ganglia view JSON file.
# See http://sourceforge.net/apps/trac/ganglia/wiki/ganglia-web-2#JSONdefinitionforviews
# for documentation on Ganglia view JSON format.
#
# == Parameters:
# $graphs       - Shortcut for describing items that represent aggregate_graphs.
# $items        - Should match exactly the JSON structure expected by Ganglia for views.
# $view_type    - If you are using aggregate_graphs, this must be set to 'standard'.
#                 'regex' will allow you to use non-aggregate graphs and match hostnames by regex.
#                 Default: 'standard'.
# $default_size - Default size for graphs.  Default: 'large'.
# $conf_dir     - Path to directory where ganglia view JSON files should live.
#                 Defaults to the appropriate directory based on WMF $::realm.  Default: /var/lib/ganglia/conf.
# $template     - The ERB template to use for the JSON file.  Only change this if you need to do fancier things than this define allows.
#
# == Examples:
# # A 'regex' (non-aggregate graph) view:
# # Note that no aggregate_graphs are used.
# # This will add 4 graphs to the 'cpu' view.
# # (i.e. cpu_user and cpu_system for each myhost0 and myhost1)
# $host_regex = 'myhost[01]'
# ganglia::view { 'cpu':
#   view_type => 'regex',
#   items     => [
#     {
#       'metric'   => 'cpu_user',
#       'hostname' => $host_regex,
#     }
#     {
#       'metric'   => 'cpu_system',
#       'hostname' => $host_regex,
#     }
#   ],
# }
#
#
# # Use the $graphs parameter to describe aggregate graphs.
# # You can describe the same graphs to add with $items.
# # $graphs is just a shortcut.  aggregate_graphs in $items
# # are a bit overly verbose.
# $host_regex = 'emery|oxygen|gadolinium'
# ganglia::view { 'udp2log':
#   graphs => [
#     {
#       'host_regex'   => $host_regex,
#       'metric_regex' => 'packet_loss_average',
#     }
#     {
#       'host_regex'   => $host_regex,
#       'metric_regex' => 'drops',
#     }
#     {
#       'host_regex'   => $host_regex,
#       'metric_regex' => 'packet_loss_90th',
#     }
#   ],
# }
#
define ganglia::view(
    $graphs       = [],
    $items        = [],
    $view_type    = 'standard',
    $default_size = 'large',
    $conf_dir     = "${ganglia::web::ganglia_confdir}/conf",
    $template     = 'ganglia/ganglia_view.json.erb',
    $ensure       = 'present'
)
{
    require ganglia::web

    # require ganglia::web
    $view_name = $name
    file { "${conf_dir}/view_${name}.json":
        content => template($template),
        ensure  => $ensure,
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
        notify => Service['gmond'],
    }
    file { "/etc/ganglia/conf.d/${plugin}.pyconf":
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("ganglia/plugins/${plugin}.pyconf.erb"),
        notify  => Service['gmond'],
    }
}

# Copied from nagios::ganglia::monitor::enwiki
# Will run on hume to use the local MediaWiki install so that we can use
# maintenance scripts recycling DB connections and taking a few secs, not mins
class misc::monitoring::jobqueue {

    cron {
        all_jobqueue_length:
            command => "/usr/bin/gmetric --name='Global JobQueue length' --type=int32 --conf=/etc/ganglia/gmond.conf --value=$(/usr/local/bin/mwscript extensions/WikimediaMaintenance/getJobQueueLengths.php --totalonly | grep -oE '[0-9]+') > /dev/null 2>&1",
            user => mwdeploy,
            ensure => present;
    }
    # duplicating the above job to experiment with gmetric's host spoofing so as to
    # gather these metrics in a fake host called "www.wikimedia.org"
    cron {
        all_jobqueue_length_spoofed:
            command => "/usr/bin/gmetric --name='Global JobQueue length' --type=int32 --conf=/etc/ganglia/gmond.conf --spoof 'www.wikimedia.org:www.wikimedia.org' --value=$(/usr/local/bin/mwscript extensions/WikimediaMaintenance/getJobQueueLengths.php --totalonly | grep -oE '[0-9]+') > /dev/null 2>&1",
            user => mwdeploy,
            ensure => present;
    }
}
