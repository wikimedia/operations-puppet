define deployment::deployment_repo_dependencies_link($deployment_dependencies_dir="/var/lib/git-deploy/dependencies", $target) {
  file { "${deployment_dependencies_dir}/${title}.dep":
    ensure => link,
    target => "${deployment_dependencies_dir}/${target}";
  }
}
