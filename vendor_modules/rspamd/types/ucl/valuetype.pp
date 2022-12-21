# == Type: Rspamd::ValueType
#
# @summary simple enum for possible types of config values.
#
# Simple enum for possible types of config values.
#
# Can be used in rspamd::config definitions to force a certain type.
#
# @author Bernhard Frauendienst <puppet@nospam.obeliks.de>
#
type Rspamd::Ucl::ValueType = Enum['auto', 'string', 'number', 'boolean', 'array']
