# == Function: shell_exports( hash $variables [, bool $uppercase_keys = true ] )
#
# Generate shell environment variable declarations out of a Puppet hash.
#
# The hash keys are used as the variable names, and the values as
# the variable's values. Values are automatically quoted with double
# quotes. If the second parameter is true (the default), keys are
# automatically uppercased.
#
# === Examples
#
# Invocation:
#
#  shell_exports({
#    apache_run_user => 'apache',
#    apache_pid_file => '/var/run/apache2/apache2.pid',
#  })
#
# Output:
#
#  export APACHE_RUN_USER="apache"
#  export APACHE_PID_FILE="/var/run/apache2/apache2.pid"
#
module Puppet::Parser::Functions
  newfunction(:shell_exports, :type  => :rvalue, :arity => 1) do |args|
    vars, uppercase_keys = args
    fail(ArgumentError, 'validate_ensure(): hash argument required') unless vars.is_a?(Hash)
    vars = Hash[vars.map { |k, v| [k.upcase, v] }] unless uppercase_keys == false
    vars.sort.map { |k, v| "export #{k}=#{v.to_pson}" }.push('').join("\n")
  end
end
