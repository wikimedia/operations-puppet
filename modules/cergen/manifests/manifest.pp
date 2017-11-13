# == Define cergen
# Installs a cergen certificate manifest file into /etc/cergen/manifests.d
# This does not handle generation of certificates with cergen CLI.
# You should manually run cergen CLI and commit the resulting files to puppet and private
# repositories.
#
# Parameters:
# [*ensure*]
#
# [*source*]
#
# [*content*]
#
define cergen::manifest(
    $ensure  = 'present',
    $source  = undef,
    $content = undef,
) {
    require ::cergen

    if $source == undef and $content == undef and $ensure == 'present' {
        fail('you must provide either "source" or "content", or ensure must be "absent"')
    }

    if $source != undef and $content != undef  {
        fail('"source" and "content" are mutually exclusive')
    }

    file { "${::cergen::manifests_path}/${title}.certs.yaml":
        ensure  => $ensure,
        mode    => '0400'
        content => $content,
        source  => $source,
    }
}
