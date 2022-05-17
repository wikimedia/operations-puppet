# SPDX-License-Identifier: Apache-2.0
type Bgpalerter::Report::Params = Variant[
    Bgpalerter::Report::Params::Email,
    Bgpalerter::Report::Params::File,
    Bgpalerter::Report::Params::Webex,
    Bgpalerter::Report::Params::Kafka,
    Bgpalerter::Report::Params::Webex,
    Bgpalerter::Report::Params::Slack,
    Bgpalerter::Report::Params::Syslog,
    Bgpalerter::Report::Params::Telegram,
    Bgpalerter::Report::Params::Webex,
    Bgpalerter::Report::Params::Http,
    Bgpalerter::Report::Params::Pullapi,
]
