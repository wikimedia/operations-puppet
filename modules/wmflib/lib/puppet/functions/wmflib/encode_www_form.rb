# frozen_string_literal: true

require 'uri'

# @summary
#   Convert a hash or form parameters into a uri encoded string
# @see https://ruby-doc.org/stdlib-2.6.3/libdoc/uri/rdoc/URI.html#method-c-encode_www_form
# @example
#   wmflib::encode_www_form({"q" => "ruby", "lang" => "en"})
#   => "q=ruby&lang=en"
#   wmflib::encode_www_form({"q" => ["ruby", "perl"], "lang" => "en"})
#   => "q=ruby&q=perl&lang=en"

Puppet::Functions.create_function(:'wmflib::encode_www_form') do
  # @param object the dictionary to encode
  # @return A form encode representation of the dictr
  dispatch :encode_www_form do
    param 'Hash', :object
  end

  # @param object
  #   The object to be converted
  #
  # @return [String]
  #   A form encode representation of the dictr
  def encode_www_form(object)
    URI.encode_www_form(object)
  end
end
