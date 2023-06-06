require 'puppet/provider/parsedfile'

Puppet::Type.type(:mailalias).provide(
  :aliases,
  parent: Puppet::Provider::ParsedFile,
  default_target: '/etc/aliases',
  filetype: :flat,
) do
  desc 'The alias provider for mailalias.'

  text_line :comment, match: %r{^#}
  text_line :blank, match: %r{^\s*$}

  record_line :aliases, fields: ['name', 'recipient'], separator: %r{\s*:\s*}, block_eval: :instance do
    def post_parse(record)
      if record[:recipient]
        record[:recipient] = record[:recipient].split(%r{\s*,\s*(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)}).map { |d| d.gsub(%r{^['"]|['"]$}, '') }
      end
      record
    end

    def process(line)
      ret = {}
      records = line.split(':', 4)
      ret[:name] = records[0].strip
      if records.length == 4 && records[2].strip == 'include'
        ret[:file] = records[3].strip
      else
        records = line.split(':', 2)
        ret[:recipient] = records[1].strip
      end
      ret
    end

    def to_line(record)
      if record[:recipient]
        dest = record[:recipient].map { |d|
          # Quote aliases that have non-alpha chars
          if %r{[^-+\w@.]}.match?(d)
            '"%s"' % d
          else
            d
          end
        }.join(',')
        "#{record[:name]}: #{dest}"
      elsif record[:file]
        "#{record[:name]}: :include: #{record[:file]}"
      end
    end
  end
end
