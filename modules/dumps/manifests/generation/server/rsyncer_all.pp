class dumps::generation::server::rsyncer_all(
    $xmldumpsdir = undef,
    $xmlremotedirs = undef,
    $miscdumpsdir = undef,
    $miscremotedirs = undef,
    $miscsubdirs = undef,
    $miscremotesubs = undef,
)  {
    include ::dumps::generation::server::rsyncer_common

    systemd::service { 'dumps-rsyncer':
        ensure    => 'present',
        restart   => true,
        content   => systemd_template('dumps-rsync-peers-all'),
        subscribe => [File['/usr/local/bin/rsync-via-primary.sh'], File['/usr/local/bin/rsyncer_lib.sh']],
    }
}
