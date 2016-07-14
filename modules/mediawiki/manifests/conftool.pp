# Class mediawiki::conftool
#
# Adds credentials and conftool scripts to a mediawiki host
class mediawiki::conftool {
    include ::conftool::scripts
    conftool::credentials { 'mwdeploy': }
}
