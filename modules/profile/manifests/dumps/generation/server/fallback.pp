class profile::dumps::generation::server::fallback {
    class { '::dumpsuser': }

    class { '::dumps::generation::server::dirs':
        user             => $dumpsuser::user,
        group            => $dumpsuser::group,
        deprecated_user  => 'datasets',
        deprecated_group => 'datasets',
    }
}
