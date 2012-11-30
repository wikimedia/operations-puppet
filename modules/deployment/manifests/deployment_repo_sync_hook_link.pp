define deployment_repo_sync_hook_link($deployment_global_hook_dir="/var/lib/git-deploy/hooks") {
  file { "${deployment_global_hook_dir}/sync/$title.sync":
    ensure => link,
    target => "${deployment_global_hook_dir}/sync/shared.py";
  }
}
