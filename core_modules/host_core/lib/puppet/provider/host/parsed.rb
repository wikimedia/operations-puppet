require 'puppet/provider/parsedfile'

case Facter.value(:osfamily)
when 'Solaris'
  hosts = '/etc/inet/hosts'
when 'windows'
  require 'win32/resolv'
  hosts = Win32::Resolv.get_hosts_path
else
  hosts = '/etc/hosts'
end

Puppet::Type.type(:host).provide(:parsed, parent: Puppet::Provider::ParsedFile,
                                          default_target: hosts, filetype: :flat) do
  @doc = "Installs and manages host entries.  For most systems, these
      entries will just be in `/etc/hosts`, but some systems (notably OS X)
      will have different solutions."

  confine exists: hosts

  text_line :comment, match: %r{^#}
  text_line :blank, match: %r{^\s*$}
  hosts_pattern = '^([0-9a-f:]\S+)\s+([^#\s+]\S+)\s*(.*?)?(?:\s*#\s*(.*))?$'
  record_line :parsed, fields: ['ip', 'name', 'host_aliases', 'comment'],
                       optional: ['host_aliases', 'comment'],
                       match: %r{#{hosts_pattern}},
                       post_parse: proc { |hash|
                                     # An absent comment should match "comment => ''"
                                     hash[:comment] = '' if hash[:comment].nil? || hash[:comment] == :absent
                                     unless hash[:host_aliases].nil? || hash[:host_aliases] == :absent
                                       hash[:host_aliases].gsub!(%r{\s+}, ' ') # Change delimiter
                                     end
                                   },
                       to_line: proc { |hash|
                                  [:ip, :name].each do |n|
                                    raise ArgumentError, _('%{attr} is a required attribute for hosts') % { attr: n } unless hash[n] && hash[n] != :absent
                                  end
                                  str = "#{hash[:ip]}\t#{hash[:name]}"
                                  if hash.include?(:host_aliases) && !hash[:host_aliases].nil? && hash[:host_aliases] != :absent
                                    str += "\t#{hash[:host_aliases]}"
                                  end
                                  if hash.include?(:comment) && !hash[:comment].empty?
                                    str += "\t# #{hash[:comment]}"
                                  end
                                  str
                                }

  text_line :incomplete, match: %r{(?! (#{hosts_pattern}))}
end
