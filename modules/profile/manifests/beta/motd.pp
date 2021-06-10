class profile::beta::motd {
    motd::script { 'beta_warning_and_terms':
        ensure   => present,
        priority => 1,
        source   => 'puppet:///modules/profile/beta/beta_warning_and_terms.motd'
    }
}
