Facter.add(:java_version) do
  setcode do
    version = nil
    if Facter::Util::Resolution.which('java')
      Facter::Util::Resolution.exec('java -Xmx12m -version 2>&1').lines.each do |line|
        if /^.+\sversion\s\"(.+)\"/ =~ line
          version = Regexp.last_match(1)
        end
      end
    end
    version
  end
end

Facter.add(:java) do
  java_fact = {'version' => {}}
  setcode do
    java_version = Facter.fact(:java_version).value
    unless java_fact['version'].nil?
      java_fact['version']['full'] = java_version
      tokens = java_version.split('.')
      java_fact['version']['major'] = tokens[0] == '1' ? tokens[1].to_i : tokens[0].to_i
    end
    java_fact
  end
end
