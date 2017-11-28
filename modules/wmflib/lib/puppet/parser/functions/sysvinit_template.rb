# == Function: sysvinit_template
#
# Loads a template from a predefined location, and returns its contents.
#
# Based on the value of the only mandatory argument, the template path will be
# determined as follows:
#
# ${module_name}/initscripts/${arg}.sysvinit.erb
#
module Puppet::Parser::Functions
  newfunction(:sysvinit_template, :type => :rvalue, :arity => 1) do |args|
    args << 'sysvinit'
    function_init_template(args)
  end
end
