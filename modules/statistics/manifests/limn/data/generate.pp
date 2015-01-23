
# == Define statistics::limn::data::generate
#
# Sets up daily cron jobs to run a script which
# generates csv datafiles and rsyncs those files
# to stat1001 so they can be served publicly.
#
# This requires that a repository with config to pass to generate.py
# exists at https://gerrit.wikimedia.org/r/p/analytics/limn-${title}-data.git.
#
# == Usage
#   statistics::limn::data::generate { 'mobile': }
#   statistics::limn::data::generate { 'flow': }
#   ...
#
define statistics::limn::data::generate() {
    require ::statistics::limn::data

    $user    = $::statistics::limn::data::user
    $command = $::statistics::limn::data::command

    # A repo at analytics/limn-${title}-data.git had better exist!
    $git_remote        = "https://gerrit.wikimedia.org/r/p/analytics/limn-${title}-data.git"

    # Directory at which to clone $git_remote
    $source_dir        = "${::statistics::limn::data::working_path}/limn-${title}-data"

    # config directory for this limn data generate job
    $config_dir        = "${$source_dir}/${title}/"

    # log file for the generate cron job
    $log               = "${::statistics::limn::data::log_dir}/limn-${title}-data.log"

    if !defined(Git::Clone["analytics/limn-${title}-data"]) {
        git::clone { "analytics/limn-${title}-data":
            ensure    => 'latest',
            directory => $source_dir,
            origin    => $git_remote,
            owner     => $user,
            require   => [User[$user]],
        }
    }

    # This will generate data into $public_dir/${title} (if configured correctly)
    cron { "generate_${title}_limn_public_data":
        command => "python ${command} ${config_dir} >> ${log} 2>&1",
        user    => $user,
        minute  => 0,
    }
}
