# setup script and cron that sends an
# audit log email to admins per RT-4802

class bugzilla::auditlog ($bz_path, $script_name, script_user, $rcpt_address, $sndr_address) {

    file { 'bugzilla_auditlog_file':
        ensure   => present,
        path     => "${bz_path}/${script_name}",
        owner    => 'root',
        group    => $bugzilla::auditlog::script_user,
        mode     => '0550',
        content  => template("bugzilla/scripts/${script_name}.erb",
    }

    cron { 'bugzilla_auditlog_cron':
        command => "cd ${bz_path} ; ./${script_name}",
        user    => $bugzilla::auditlog::script_user,
        hour    => '0',
        minute  => '0',
    }
}

