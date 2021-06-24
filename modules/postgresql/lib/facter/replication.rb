# replication.rb - is a postgres host running with a valid backup import?

require 'facter'

Facter.add('postgres_version') do
  setcode do
    version = nil
    if Facter::Util::Resolution.which('psql')
      Facter::Util::Resolution.exec('psql --version').lines.each do |line|
        version_split = line.split(" ")
        version = version_split[2]
      end
    end
    version
  end
end

Facter.add('postgres_replica_initialised') do
  setcode do
    initialised = nil
    pg_version_fact = Facter.fact(:postgres_version)
    unless pg_version_fact.value.nil?
      pg_version_match = pg_version_fact.value.match /^([\d\.]+)\.(\d)+$/
      pg_base_version = pg_version_match[1]
      unless pg_base_version.nil?
        if File.exists?("/srv/postgresql/#{pg_base_version}/main/backup_label.old")
          initialised = true
        else
          initialised = false
        end
      end
    end
    initialised
  end
end
