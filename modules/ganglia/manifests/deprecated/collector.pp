# == Class ganglia::deprecated::collector
# Ganglia gmetad config. Do not use this!

class ganglia::deprecated::collector {
    system::role { 'ganglia::collector': description => 'Ganglia gmetad aggregator' }

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
            fail('ganglia::deprecated::collector is deprecated and only applied to netmon1001')
        }
    }

    file { '/etc/ganglia/gmetad.conf':
        ensure  => present,
        require => Package['gmetad'],
        content => template('ganglia/deprecated/gmetad.conf.erb'),
        mode    => '0444',
    }

    service { 'gmetad':
        ensure    => running,
        require   => File['/etc/ganglia/gmetad.conf'],
        subscribe => File['/etc/ganglia/gmetad.conf'],
        hasstatus => false,
    }

}
