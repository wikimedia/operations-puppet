# This define allows you to monitor for unmerged remote changes to
# repositories that need manual merge in production as part of our workflow.
#
define monitoring::icinga::git_merge (
    $dir      = "/var/lib/git/operations/${title}",
    $user     = 'gitpuppet',
    $warning  = 600,
    $critical = 900
) {
      file { "check_${title}_needs_merge":
          ensure  => present,
          path    => "/usr/local/lib/nagios/plugins/check_${title}-needs-merge",
          owner   => root,
          group   => root,
          mode    => '0555',
          content => template('monitoring/check_git-needs-merge.erb')
      }
      nrpe::monitor_service { "${title}_merged":
          description  => "Unmerged changes on repository ${title}",
          nrpe_command => "/usr/local/lib/nagios/plugins/check_${title}-needs-merge",
          require      => File["check_${title}_needs_merge"]
      }
}
