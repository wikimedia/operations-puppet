# replication.rb - is a postgres host running with a valid backup import?

require 'facter'

Facter.add('postgres_version') do
  confine do
    Facter::Util::Resolution.which('psql')
  end
  setcode do
    Facter::Util::Resolution.exec('psql --version').strip.split[2]
  end
end

Facter.add('postgres_replica_initialised') do
  confine do
    Facter::Util::Resolution.which('psql')
    Facter::Util::Resolution.which('sudo')
  end
  setcode do
    data_dir = Facter::Util::Resolution.exec("sudo -u postgres psql -tc 'SHOW data_directory;'").strip
    File.exists?("#{data_dir}/backup_label.old")
  end
end
