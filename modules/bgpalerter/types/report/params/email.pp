# SPDX-License-Identifier: Apache-2.0
type Bgpalerter::Report::Params::Email = Struct[{
    showPaths                => Integer[0],
    senderEmail              => Stdlib::Email,
    smtp                     => Bgpalerter::Report::Params::Email::Smtp,
    notifiedEmails           => Hash[String, Array[Stdlib::Email]],
    'notifiedEmails.default' => Optional[String[1]],
}]
