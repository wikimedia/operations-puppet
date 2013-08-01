class base::motd {
    # Remove the standard help text
    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '10.04') >= 0 {
        file { '/etc/update-motd.d/10-help-text': ensure => absent; }
    }
}
