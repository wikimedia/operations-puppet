# Class: interface::rpstools
#
# Populate tools used to set RPS for an interface
#
# Note that this is explicitly split in a separate class. It is used only in
# definition interface::rps and this split allows up to avoid duplicate
# definitions of the file resource.
class interface::rpstools {
    file { '/usr/local/sbin/interface-rps':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/interface/interface-rps.py',
    }
}
