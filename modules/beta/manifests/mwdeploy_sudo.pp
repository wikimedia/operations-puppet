# == Class: beta::mwdeploy_sudo
#
# Manage sudo rights for the mwdeploy user.
#
class beta::mwdeploy_sudo {
    # Grant mwdeploy sudo rights to run anything as itself, apache or
    # l10nupdate and to (re)start the hhvm fcgi service. This is a subset of
    # the rights granted to the wikidev group by the mediawiki::users class.
    sudo::user { 'mwdeploy' :
        privileges => [
            'ALL = (apache,mwdeploy,l10nupdate) NOPASSWD: ALL',
            'ALL = (root) NOPASSWD: /sbin/restart hhvm',
            'ALL = (root) NOPASSWD: /sbin/start hhvm',
        ]
    }
}
