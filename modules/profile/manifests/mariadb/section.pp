# Title should be the section name
define profile::mariadb::section(
    Profile::Mariadb::Valid_section $section = $title,
    Boolean $mention_alias = false,
) {
    $alias = $mention_alias ? {
        true => " (alias: mysql.${title})",
        false => '',
    }
    # Add the db section to the motd
    motd::script { "db-section-${title}":
        priority => 6,
        content  => "#!/bin/sh\necho 'DB section ${title}${alias}'\n",
    }

    # Deploy dbbackup_metrics.py on m1 hosts
    # It runs only on multiinstance hosts (see script)
    if $section == 'm1' {
        include profile::mariadb::dbbackup_metrics
    }
}
