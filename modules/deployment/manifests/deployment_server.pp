class deployment::deployment_server($deployment_conffile="/etc/git-deploy/git-deploy.conf", $deployment_restrict_umask="002", $deployment_block_file="/etc/ROLLOUTS_BLOCKED", $deployment_support_email="", $deployment_repo_name_detection="dot-git-parent-dir", $deployment_announce_email="", $deployment_send_mail_on_sync="false", $deployment_send_mail_on_revert="false", $deployment_log_directory="/var/log/deploy", $deployment_log_timing_data="false", $deployment_global_hook_dir="/usr/local/bin/git-deploy", $deployment_per_repo_config={}) {
  package { ["git-deploy", "git-core"]:
    ensure => present;
  }

  if ($deployment_global_hook_dir) {
    file {
      "${$deployment_global_hook_dir}":
        ensure => directory,
        mode => 0555,
        owner => root,
        group => root;
      "${$deployment_global_hook_dir}/shared.py":
        source => "puppet:///deployment/git-deploy/shared.py",
        mode => 0555,
        owner => root,
        group => root,
        require => [File["${$deployment_global_hook_dir}"]];
    }
  }
  file {
    "/etc/gitconfig":
      content => template("deployment/git-deploy/gitconfig.erb"),
      mode => 0444,
      owner => root,
      group => root,
      require => [Package["git-core"]];
    "${deployment_conffile}":
      content => template("deployment/git-deploy/git-deploy.conf.erb"),
      mode => 0444,
      owner => root,
      group => root;
  }
}
