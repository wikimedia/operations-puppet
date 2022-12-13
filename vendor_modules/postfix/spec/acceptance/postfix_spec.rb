require 'spec_helper_acceptance'

describe 'postfix' do
  let(:pp) do
    <<-MANIFEST
      class { 'postfix':
        inet_protocols => ['ipv4'],
      }

      postfix::lookup::database { '/etc/aliases':
        type       => 'hash',
        input_type => 'aliases',
      }

      Mailalias <||> -> Postfix::Lookup::Database['/etc/aliases']

      mailalias { 'foo':
        recipient => ['bar'],
        target    => '/etc/aliases',
      }
    MANIFEST
  end

  it 'applies idempotently' do
    idempotent_apply(pp)
  end

  describe package('postfix') do
    it { is_expected.to be_installed }
  end

  describe file('/etc/postfix') do
    it { is_expected.to be_directory }
    it { is_expected.to be_mode 755 }
    it { is_expected.to be_owned_by 'root' }
    it { is_expected.to be_grouped_into 'root' }
  end

  describe file('/etc/postfix/main.cf') do
    it { is_expected.to be_file }
    it { is_expected.to be_mode 644 }
    it { is_expected.to be_owned_by 'root' }
    it { is_expected.to be_grouped_into 'root' }
  end

  describe file('/etc/postfix/master.cf') do
    it { is_expected.to be_file }
    it { is_expected.to be_mode 644 }
    it { is_expected.to be_owned_by 'root' }
    it { is_expected.to be_grouped_into 'root' }
  end

  describe service('postfix') do
    it { is_expected.to be_enabled }
    it { is_expected.to be_running }
  end

  describe file('/etc/aliases') do
    it { is_expected.to be_file }
    it { is_expected.to be_mode 644 }
    it { is_expected.to be_owned_by 'root' }
    it { is_expected.to be_grouped_into 'root' }
  end

  describe file('/etc/aliases.db') do
    it { is_expected.to be_file }
    it { is_expected.to be_mode 644 }
    it { is_expected.to be_owned_by 'root' }
    it { is_expected.to be_grouped_into 'root' }
  end

  describe command('postmap -q foo hash:/etc/aliases') do
    its(:exit_status) { is_expected.to eq 0 }
    its(:stdout) { is_expected.to eq "bar\n" }
  end
end
