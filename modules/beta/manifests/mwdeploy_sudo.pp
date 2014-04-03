# == Class: beta::mwdeploy_sudo
#
# Manage sudo rights for the mwdeploy user.
#
class beta::mwdeploy_sudo {
    # Grant mwdeploy sudo rights to run anything as itself, apache or
    # l10nupdate. This is a subset of the rights granted to the wmdeploy group
    # by the mediawiki::users::sudo class
    sudo_user { 'mwdeploy' :
        privileges => [
            'ALL = (apache,mwdeploy,l10nupdate) NOPASSWD: ALL',
        ]
    }
}
