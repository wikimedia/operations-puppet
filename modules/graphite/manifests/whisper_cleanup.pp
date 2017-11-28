# Cleanup whisper directories from old metric files
#
# === Parameters
#
# [*directory*] The directory to cleanup
# [*keep_days*] Files older than this many days will be deleted
# [*user*] Username to run the commands as

define graphite::whisper_cleanup (
  $directory,
  $keep_days = 30,
  $user = '_graphite',
) {
    cron { $title:
        command => "[ -d ${directory} ] && find ${directory} -type f -mtime +${keep_days} -delete && find ${directory} -type d -empty -delete",
        user    => $user,
        hour    => fqdn_rand(24, $title),
        minute  => fqdn_rand(60, $title),
    }
}
