# @summary manage backup timers
class gitlab::backup (
    Wmflib::Ensure $ensure                  = 'present',
    # should be some Enum[daily, monthly, disabled]
    String         $full                    = 'daily',
    String         $partial                 = 'hourly',
    String         $config                  = 'disabled',
    Boolean        $rsyncable_gzip          = true,
    Integer[1]     $max_concurrency         = 4,
    Integer[1]     $max_storage_concurrency = 1,
) {
    $full_cmd = @("CONFIG"/L)
    /usr/bin/gitlab-backup create CRON=1 STRATEGY=copy \
    GZIP_RSYNCABLE=${rsyncable_gzip.bool2str('yes', 'no')} \
    GITLAB_BACKUP_MAX_CONCURRENCY=${max_concurrency} \
    GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY=${max_storage_concurrency} \
    | CONFIG
    $partial_cmd = "${full_cmd} SKIP=uploads,builds,artifacts,lfs,registry,pages"
    # TODO create timer::job for full backup
    $full_ensure = $full == 'disabled' ? {
        true    => 'absent',
        default => $ensure,
    }

    # TODO create timer::job for partial backup
    $partial_ensure = $full == 'disabled' ? {
        true    => 'absent',
        default => $ensure,
    }
    # TODO create timer::job for config backup
    # TODO create timer::job for config backup cleanup
    $config_ensure = $full == 'disabled' ? {
        true    => 'absent',
        default => $ensure,
    }

}
