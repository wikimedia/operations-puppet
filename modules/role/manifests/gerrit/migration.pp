# temp allow rsyncing gerrit data to new server
class role::gerrit::migration {

    system::role {'gerrit::migration':
        description => 'temp role to allow migrating Gerrit data to a new server',
    }

    include ::profile::standard
    include ::profile::gerrit::migration
}
