# @summary quotes a string as a valid UCL string
# @note this is internal API and should never be required by users
#
# @return the quoted string suitable for inclusion in a ucl config file
#
# @author Bernhard Frauendienst <puppet@nospam.obeliks.de>
#
Puppet::Functions.create_function(:'rspamd::ucl::quote_string_value') do
  dispatch :to_ucl_string do
    param 'String', :value
  end

  def to_ucl_string(value)
    require 'json'

    # use json string encoding, this should be fully compatible with ucl
    JSON.generate(value, quirks_mode: true) # need quirks_mode to allow string generation
  end
end
