# Only used in labstore1003, can be deprecated once that
# server stops serving dumps post migrating to labstore1006|7
class profile::dumps::web::dumpsuser {
    class { '::dumpsuser': }
}
