# == Function: secret('some/private/source/file.txt')
#
# Alternate method to serve the contents of a files from a private
# repository/module on the puppetmaster without exposing them by puppet's
# fileserver. This is a bit more secure and less trouble than creating a whole
# lot of host and mount ACLs. Note this function supports lists with file
# search behavior similar to puppet source => [].
#
# === Example:
#
# Invocation:
#
#  file { '/etc/file.conf':
#    ensure  => 'file',
#    mode  => '0640',
#    content => secret("what/${role}-file.conf", 'what/default-file.conf'),
#  }
#
# Result:
#
# puppetmaster will work down the list (left to right) looking for a match in
# the private secret/secrets collection. The first file that matches will be read and
# written as {node}:/etc/file.conf. If no match is found, the puppet run fails.
#
require 'pathname'

module Puppet::Parser::Functions
  newfunction(:secret, :type => :rvalue) do |args|
    mod_name = 'secret'
    secs_subdir = '/secrets/'

    if mod = Puppet::Module.find(mod_name)
      mod_path = mod.path()
    else
      fail("secret(): Private module #{mod_name} wasn't loaded. Check your module path.")
    end

    nonviable_files = []

    args.each do |in_path|
      if in_path.is_a?(String)
        sec_path = mod_path + secs_subdir + in_path
        final_path = Pathname.new(sec_path).cleanpath()
        if final_path.file?
          if final_path.readable?
            return final_path.read()
          else
            fail(ArgumentError, "secret(): Input file #{final_path} is present, but not readable.")
          end
        else
          nonviable_files.push(in_path)
        end
      else
        fail(ArgumentError, "secret(): Input must be exactly one string, but this isn't: [#{in_path}]")
      end
    end

    list_of_fail = nonviable_files.join(', ')
    fail(ArgumentError, "secret(): No viable files found from input list: [#{list_of_fail}]")

  end
end
