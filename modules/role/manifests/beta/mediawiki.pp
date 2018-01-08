# == Class role::beta::mediawiki
#
# Allow mwdeploy to login from scap deployment host. Adds an exception in
# /etc/security/access.conf to work around labs-specific restrictions
# Please consider adding profile::beta::mediawiki to your instance
# roles instead, it does the same thing.  This role is here only for
# backwards compatibility.
#
# filtertags: labs-project-deployment-prep
class role::beta::mediawiki {
    include ::profile::beta::mediawiki
}
