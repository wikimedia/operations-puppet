class role::ganglia::config {
    # TODO: hiera this
    $rra_sizes = '"RRA:AVERAGE:0.5:1:360" "RRA:AVERAGE:0.5:24:245" "RRA:AVERAGE:0.5:168:241" "RRA:AVERAGE:0.5:672:241" "RRA:AVERAGE:0.5:5760:371"'

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
        'Miscellaneous eqiad'            => 'carbon.wikimedia.org ms1004.eqiad.wmnet',
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
        'Analytics cluster eqiad'        => 'analytics1013.eqiad.wmnet analytics1014.eqiad.wmnet analytics1019.eqiad.wmnet',
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
}

# A role that includes all the needed stuff to run a ganglia web frontend
class role::ganglia::web {
    include role::ganglia::config

    install_certificate{ 'ganglia.wikimedia.org': }

    $gmetad_root = '/srv/ganglia'
    $rrd_rootdir = "${gmetad_root}/rrds"
    $gmetad_socket = '/var/run/rrdcached-gmetad.sock'
    $gweb_socket = '/var/run/rrdcached-gweb.sock'

    class { 'ganglia_new::gmetad::rrdcached':
        rrdpath       => $rrd_rootdir,
        gmetad_socket => $gmetad_socket,
        gweb_socket   => $gwebsocket,
        journal_dir      => '/srv/rrdcached_journal',
    }

    # TODO: Automate the gmetad trusted hosts variable
    class { 'ganglia_new::gmetad':
        grid             => 'Wikimedia',
        authority        => 'http://ganglia.wikimedia.org',
        gmetad_root      => $gmetad_root,
        rrd_rootdir      => $rrd_rootdir,
        rrdcached_socket => $gmetad_socket,
        trusted_hosts    => [
                        '208.80.154.149', # bast1001
                        '208.80.154.14', # neon
                        '10.64.32.13', # terbium
                        ],
        data_sources     => $role::ganglia::config::data_sources,
        rra_sizes        => $role::ganglia::config::rra_sizes,
    }

    class { 'ganglia_new::web':
        rrdcached_socket => $gweb_socket,
        gmetad_root      => $gmetad_root,
    }

    ferm::service { 'ganglia_http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'ganglia_https':
        proto => 'tcp',
        port  => '443',
    }

    ferm::service { 'gmond_udp':
        proto  => 'udp',
        port   => '8649',
        srange => '$ALL_NETWORKS',
    }

    ferm::service { 'gmond_tcp':
        proto  => 'tcp',
        port   => '8649',
        srange => '$ALL_NETWORKS',
    }

    ferm::service { 'gmetad_xml':
        proto  => 'tcp',
        port   => '8653',
        srange => '$ALL_NETWORKS',
    }

    ferm::service { 'gmetad':
        proto  => 'tcp',
        port   => '8654',
        srange => '$ALL_NETWORKS',
    }

    # Get better insight into how disks are faring
    ganglia::plugin::python { 'diskstat': }

    monitoring::service { 'ganglia_http':
        description   => 'HTTP',
        check_command => 'check_http',
    }
    include role::backup::host
    backup::set { 'var-lib-ganglia': }
    backup::set { 'srv-ganglia': }

    Class['ganglia_new::gmetad::rrdcached'] -> Class['ganglia_new::gmetad']
    Class['ganglia_new::gmetad'] -> Class['ganglia_new::web']
}
