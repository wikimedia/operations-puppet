# == Class: beta::saltmaster::tools
#
# Provisions tools and scripts that are helpful on the salt master.
#
class beta::saltmaster::tools {
    file { '/usr/local/bin/beta-apaches':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/beta/scripts/beta-apaches';
    }
}
