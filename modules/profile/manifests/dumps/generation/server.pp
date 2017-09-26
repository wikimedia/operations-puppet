class profile::dumps::generation::server {
    class { '::dumpsuser': }

    class { '::dumps::generation::server::dirs':
        user  => $dumpsuser::user,
        group => $dumpsuser::group,
    }
}
