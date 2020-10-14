# Title should be the section name
define profile::mariadb::section(
    Profile::Mariadb::Valid_section $section = $title,
) {
    # Add the db section to the motd, directly after the system::role line.
    motd::script { "db-section-${title}":
        priority => 6,
        content  => "#!/bin/sh\necho 'DB section ${title}'\n",
    }
}
