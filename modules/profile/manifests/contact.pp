# @summary add a contact to the system
# @title the title should represent the area the contact is responsible for
# @param param A list of contacts, can be personal names (referring to a shell username
#        as found in data.yaml or team names (minimum of 3 characters)
define profile::contact (
    Array[String[3],1] $contacts,
) {
    include profile::contacts
    unless $title.stdlib::start_with('profile') {
        fail("The title (${title}) should map to a profile")
    }
    concat::fragment {"${title} contacts":
        target  => $profile::contacts::contacts_file,
        order   => '10',
        # [4,-1] to strip the yaml '---' header as this is a fragment
        content => {$title => $contacts}.to_yaml[4,-1]
    }
}
