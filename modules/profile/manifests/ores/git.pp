class profile::ores::git {
  class { 'git::lfs': }

  # Up to Stretch scap was configured to run: `git lfs install --global`
  # right before cloning a repo on a target node for the first time.
  # The step was needed to add git lfs filters to pull down binaries from
  # Gerrit correctly (rather than leaving their text files with SHA references).
  # Info:
  # https://phabricator.wikimedia.org/rMSCAa2c3add38e341956fbf4fcf376e4cf5976e06f5d
  # The ML team ended up releasing a new version of scap for Buster, since
  # the '--global' parameter was not accepted anymore (indeed it wasn't ever
  # mentioned in the related man pages of all versions).
  # Info: https://gerrit.wikimedia.org/r/c/mediawiki/tools/scap/+/785154
  # With the above new version of scap though, scap/git-lfs did not pull
  # down binaries anymore on the target nodes, leaving only text files with SHAs.
  # Running `git lfs install --system` solved the issue, but it caused
  # /etc/gitconfig to be modified, and we prefer to use puppet.
  if debian::codename::ge('buster') {
      git::systemconfig { 'lfs-filters':
          settings => {
              'filter "lfs"' => {
                  'clean'    => 'git-lfs clean -- %f',
                  'smudge'   => 'git-lfs smudge -- %f',
                  'process'  =>  'git-lfs filter-process',
                  'required' => 'true',
                }
          }
      }
  }
}