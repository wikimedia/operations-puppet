class profile::wmcs::paws::common (
) {
    motd::script { 'paws-banner':
        ensure => present,
        source => 'puppet:///modules/profile/wmcs/paws/paws-banner.sh',
    }
}
