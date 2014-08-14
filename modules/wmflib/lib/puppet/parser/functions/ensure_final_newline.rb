# == Function: ensure_final_newline
#
# If the argument is a string, ensure it ends with a final newline.
# If it is not a string, pass it through unmodified.
#
# This function is designed to make it easier to write custom Puppet
# resource types that delegate to file resources and that take
# either a "content" or a "source" parameter.
#
module Puppet::Parser::Functions
  newfunction(
    :ensure_final_newline,
    :arity => 1,
    :type => :rvalue,
    :doc  => <<-END
      If the argument is a string, ensure it ends with a final newline.
      If it is not a string, pass it through unmodified.

      This function is designed to make it easier to write custom Puppet
      resource types that delegate to file resources and that take
      either a "content" or a "source" parameter.

    END
  ) do |args|
    val = args.first
    val.is_a?(String) && val[-1, 1] != "\n" ? val << "\n" : val
  end
end
