# == class git::params
# Contains common parameters for git repositories
class git::params {
    $source_format = {
        'gerrit'      => 'https://gerrit.wikimedia.org/r/p/%s.git',
        'phabricator' => 'https://phabricator.wikimedia.org/diffusion/%.git',
    }
}
