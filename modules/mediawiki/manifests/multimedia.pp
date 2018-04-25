# == Class: mediawiki::multimedia
#
# Provisions packages and configurations used by MediaWiki for video processing.
#
class mediawiki::multimedia {
    include ::mediawiki::packages::multimedia
    include ::mediawiki::users
}
