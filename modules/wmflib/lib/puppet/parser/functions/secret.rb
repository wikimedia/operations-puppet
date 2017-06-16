require 'pathname'

module Puppet::Parser::Functions
  newfunction(:secret, :type => :rvalue) do |args|
    mod_name = 'secret'
    secs_subdir = '/secrets/'

    if args.length != 1 || !args.first.is_a?(String)
      fail(ArgumentError, 'secret(): exactly one string arg')
    end
    in_path = args.first

    mod = Puppet::Module.find(mod_name)
    unless mod
      fail("secret(): Module #{mod_name} not found")
    end

    sec_path = mod.path + secs_subdir + in_path
    final_path = Pathname.new(sec_path).cleanpath

    # Bail early if it's not a regular, readable file
    unless final_path.file? && final_path.readable?
      fail(ArgumentError, "secret(): invalid secret #{in_path}")
    end

    final_path.read
  end
end
