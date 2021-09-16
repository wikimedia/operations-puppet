class profile::mediawiki::videoscaler()
{
    include mediawiki::users

    ensure_packages('ffmpeg')
}
