class role::releases {
    system::role { 'releases': description => 'Releases webserver' }

    monitor_service { 'http':
        description     => 'HTTP',
        check_command   => 'check_http',
    }

    class { '::releases':
        sitename     => 'releases.wikimedia.org',
        docroot      => 'releases',
    }

    # mobile app releases
    role::releases::access { 'brion': group => 'mobileupld' }
    role::releases::access { 'yuvipanda': group => 'mobileupld' } # RT 7068
    role::releases::access { 'dbrant': group => 'mobileupld' } # RT 7399

    # mediawiki releases
    role::releases::access { 'csteipp': group => 'mwupld' }
    role::releases::access { 'hashar': group => 'mwupld' } # RT 6861
    role::releases::access { 'mah': group => 'mwupld' } # RT 6861
    role::releases::access { 'mglaser': group => 'mwupld' } # RT 6861
    role::releases::access { 'reedy': group => 'mwupld' } # RT 6861

    ferm::service { 'releases_http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'releases_https':
        proto => 'tcp',
        port  => '443',
    }

}

class role::releases::groups {
    group { 'mwupld':
            ensure => 'present',
    }
    group { 'mobileupld':
            ensure => 'present',
    }
}

define role::releases::access ( $user=$title, $group='wikidev' ) {
    require 'role::releases::groups'
    require "accounts::${user}"
    Class['role::releases::groups'] -> Class["accounts::${user}"]
    User<|title == $user|>       { groups +> [ $group ] }
}
