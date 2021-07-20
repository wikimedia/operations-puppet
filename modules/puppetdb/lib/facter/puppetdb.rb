require 'facter'

Facter.add(:puppetdb) do
  details = {}
  details['stockpile_initialized'] = File.exist?('/var/lib/puppetdb/stockpile/cmd/stockpile')
  setcode { details }
end
