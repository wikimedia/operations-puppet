# vim: set et ts=4 sw=4:

# Set up a Jenkins slave suitable for Continuous Integration jobs execution.
# You will need to setup the Gerrit replication in role::gerrit::production
class role::contint::jenkins::slave {

    include contint::packages,
        role::gerrit::production::replicationdest,
        role::jenkins::slave::production

    # /srv/ssd should have been mounted at the node level. If that is not the
    # case we have to fail.
    Class['role::jenkins::slave::production'] -> Mount['/srv/ssd']

    # Setup Gerrit replication destination:
    file { '/srv/ssd/gerrit':
        ensure => 'directory',
        owner  => 'gerritslave',
        group  => 'root',
        mode   => '0755',
    }

}
