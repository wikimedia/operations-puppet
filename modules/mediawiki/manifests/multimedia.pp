# == Class: mediawiki::multimedia
#
# Provisions packages and configurations used by MediaWiki for image
# and video processing.
#
class mediawiki::multimedia {
    include ::mediawiki::packages::multimedia
    include ::mediawiki::packages::fonts
    include ::mediawiki::users
}
