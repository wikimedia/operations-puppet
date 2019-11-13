class profile::mediawiki::videoscaler()
{
    include ::mediawiki::users

    # Backport of libvpx 1.7 and row-mt support, can be removed once
    # video scalers are migrated to Debian buster
    apt::repository { 'ffmpeg-vp9':
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => 'stretch-wikimedia',
        components => 'component/vp9',
    }

    package { 'ffmpeg':
        ensure  => present,
        require => [ Apt::Repository['ffmpeg-vp9'], Exec['apt-get update']],
    }
}
