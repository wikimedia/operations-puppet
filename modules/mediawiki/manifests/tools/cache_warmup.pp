# SPDX-License-Identifier: Apache-2.0
class mediawiki::tools::cache_warmup( $ensure = present ) {
    # Include this class on a host to install the warmup script, which is
    # useful for warming cluster (e.g., memcache) or local (e.g., APCu) caches.
    # NOTE: T369921 - For full functionality, the host must have kubernetes
    # configuration / credentials present (e.g., a deployment host).
    # See T156922 for the original motivation behind this tool.

    ensure_packages('python3-requests')

    # Ensure all files we have in puppet are present in the directory, but allow
    # users to write files in the directory without purging them.
    file { '/var/lib/mediawiki-cache-warmup':
        ensure  => stdlib::ensure($ensure, 'directory'),
        owner   => $::mediawiki::users::web,
        recurse => remote,
        group   => 'wikidev',
        mode    => '0775',
        source  => 'puppet:///modules/mediawiki/tools/mediawiki-cache-warmup/',
    }

}
