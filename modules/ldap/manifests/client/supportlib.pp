# == class: ldap::supportlib
#
# Provides the single file ldapsupportlib 'library'
# for scripts that use it
# FIXME: Kill it with fire.
class ldap::supportlib {
    require_package('python-ldap')

    file { '/usr/local/lib/python2.7/dist-packages/ldapsupportlib.py':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/ldap/scripts/ldapsupportlib.py',
    }

}
