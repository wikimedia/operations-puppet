#SPDX-License-Identifier: Apache-2.0
#@summary Class to install ircstream a mediawiki to IRC streaming service. See: https://github.com/paravoid/ircstream
class ircstream (
){

    ensure_packages(['ircstream'])
}
