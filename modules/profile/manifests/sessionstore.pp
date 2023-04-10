# sets up a service for session storage (T206016)
class profile::sessionstore {

    # needed for T219560
    class {'passwords::cassandra': }
}
