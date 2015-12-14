class mediawiki::conftool {
    include ::conftool::scripts
    conftool::credentials { 'mwdeploy':
    }
}
