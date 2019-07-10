# Shared profile for front- and back-end puppetmasters.
#
# $config:  Dict merged with front- or back- specifics and then passed
#           to ::puppetmaster as $config
#
# $storeconfigs: Accepts values of 'puppetdb', 'activerecord', and 'none'
#
class profile::puppetmaster::common (
    $base_config,
    $storeconfigs = hiera('profile::puppetmaster::common::storeconfigs', 'activerecord'),
) {
    include passwords::puppet::database

    $env_config = {
        'environmentpath'  => '$confdir/environments',
        'default_manifest' => '$confdir/manifests',
    }

    $activerecord_config =   {
        'storeconfigs'      => true,
        'thin_storeconfigs' => true,
    }
    $active_record_db = {
        'dbadapter'         => 'mysql',
        'dbuser'            => 'puppet',
        'dbpassword'        => $passwords::puppet::database::puppet_production_db_pass,
        'dbserver'          => 'm1-master.eqiad.wmnet',
        'dbconnections'     => '256',
    }

    $puppetdb_config = {
        storeconfigs         => true,
        storeconfigs_backend => 'puppetdb',
        reports              => 'puppetdb',
    }

    if $storeconfigs == 'puppetdb' {
        apt::repository { 'wikimedia-puppetdb4':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => "${::lsbdistcodename}-wikimedia",
            components => 'component/puppetdb4',
            before     => Class['puppetmaster::puppetdb::client'],
        }
        $puppetdb_host = hiera('profile::puppetmaster::common::puppetdb_host')
        class { 'puppetmaster::puppetdb::client':
            host                   => $puppetdb_host,
        }
        $config = merge($base_config, $puppetdb_config, $active_record_db, $env_config)
    } elsif $storeconfigs == 'activerecord' {
            $config = merge($base_config, $activerecord_config, $active_record_db, $env_config)
    } else {
            $config = merge($base_config, $env_config)
    }

    # Don't attempt to use puppet-master service on stretch, we're using passenger.
    if os_version('debian >= stretch') {
        service { 'puppet-master':
            ensure  => stopped,
            enable  => false,
            require => Package['puppet'],
        }
    }
}
