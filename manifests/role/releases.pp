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

    role::releases::access { 'brion': group => 'mobileupld' }
    role::releases::access { 'ypanda': group => 'mobileupld' } # RT 7068
    role::releases::access { 'csteipp': group => 'mwupld' }
    role::releases::access { 'hashar': group => 'mwupld' } # RT 6861
    role::releases::access { 'mah': group => 'mwupld' } # RT 6861
    role::releases::access { 'mglaser': group => 'mwupld' } # RT 6861
    role::releases::access { 'reedy': group => 'mwupld' } # RT 6861
    role::releases::access { 'csteipp': group => 'mwupld' } # RT 7188

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
    require 'groups::wikidev'
    require "accounts::${user}"
    Class['groups::wikidev'] -> Class['role::releases::groups'] ->
        Class["accounts::${user}"]
    User<|title == $user|>       { groups +> [ $group ] }
}
