# == Class: mediawiki::firejail
#
# This Puppet class provides profile data for firejail, a sandbox to restrict
# an application environment. These profiles are used to contain the image
# scaling process (since imagemagick has a high risk security profile).
# It also provides a wrapper script to invoke imagemagick's convert via firejail.

class mediawiki::firejail {

    file { '/usr/local/bin/mediawiki-firejail-ffmpeg':
        source => 'puppet:///modules/mediawiki/mediawiki-firejail-ffmpeg',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/usr/local/bin/mediawiki-firejail-rsvg-convert':
        source => 'puppet:///modules/mediawiki/mediawiki-firejail-rsvg-convert',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
}
