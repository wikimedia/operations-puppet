# SPDX-License-Identifier: Apache-2.0
type Wmflib::Portrange = Pattern[/\A(?x:
    (?:
        [0-9]{1,4}|[1-5][0-9]{4}|
        6[0-4][0-9]{3}|
        65[0-4][0-9]{2}|
        655[0-2][0-9]|
        6553[0-5]
    ):(?:
        [0-9]{1,4}|
        [1-5][0-9]{4}|
        6[0-4][0-9]{3}|
        65[0-4][0-9]{2}|
        655[0-2][0-9]|
        6553[0-5]
    )
\z)/]
