# == Function: init_template
#
# Loads a template from a predefined location, and returns its contents.
#
# Based on the value of the two mandatory arguments, the template path will be
# determined as follows:
#
# ${module_name}/initscripts/${arg}.${initsystem}.erb
#
module Puppet::Parser::Functions
  newfunction(:init_template, :type => :rvalue, :arity => 2) do |args|
    tpl_name, initsystem = args
    module_name = lookupvar('module_name')
    tpl_arg = "#{module_name}/initscripts/#{tpl_name}.#{initsystem}.erb"
    function_template([tpl_arg])
  end
end
