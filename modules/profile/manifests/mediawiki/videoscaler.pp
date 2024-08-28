class profile::mediawiki::videoscaler()
{
    include mediawiki::users

    apt::package_from_component { 'ffmpeg':
        packages  => ['ffmpeg'],
        component => 'component/ffmpeg',
    }
}
