class dumps::generation::server::rsyncer_xml(
    $xmldumpsdir = undef,
    $xmlremotedirs = undef,
)  {
    include ::dumps::generation::server::rsyncer_common

    systemd::service { 'dumps-rsyncer':
        ensure    => 'present',
        restart   => true,
        content   => systemd_template('dumps-rsync-peers-xml'),
        subscribe => [File['/usr/local/bin/rsync-via-primary.sh'], File['/usr/local/bin/rsyncer_lib.sh']],
    }
}
