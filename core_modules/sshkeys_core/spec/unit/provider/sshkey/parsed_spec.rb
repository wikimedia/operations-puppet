require 'spec_helper'

describe 'sshkey parsed provider' do
  subject { provider }

  let(:type) { Puppet::Type.type(:sshkey) }
  let(:provider) { type.provider(:parsed) }

  after :each do
    subject.clear
  end

  def key
    'AAAAB3NzaC1yc2EAAAABIwAAAQEAzwHhxXvIrtfIwrudFqc8yQcIfMudrgpnuh1F3AV6d2BrLgu/yQE7W5UyJMUjfj427sQudRwKW45O0Jsnr33F4mUw+GIMlAAmp9g24/OcrTiB8ZUKIjoPy/cO4coxGi8/NECtRzpD/ZUPFh6OEpyOwJPMb7/EC2Az6Otw4StHdXUYw22zHazBcPFnv6zCgPx1hA7QlQDWTu4YcL0WmTYQCtMUb3FUqrcFtzGDD0ytosgwSd+JyN5vj5UwIABjnNOHPZ62EY1OFixnfqX/+dUwrFSs5tPgBF/KkC6R7tmbUfnBON6RrGEmu+ajOTOLy23qUZB4CQ53V7nyAWhzqSK+hw==' # rubocop:disable Layout/LineLength
  end

  it 'parses the name from the first field' do
    expect(subject.parse_line('test ssh-rsa ' + key)[:name]).to eq('test')
  end

  it 'parses the first component of the first field as the name' do
    expect(subject.parse_line('test,alias ssh-rsa ' + key)[:name]).to eq('test')
  end

  it 'parses host_aliases from the remaining components of the first field' do
    expect(subject.parse_line('test,alias ssh-rsa ' + key)[:host_aliases]).to eq(['alias'])
  end

  it 'parses multiple host_aliases' do
    expect(subject.parse_line('test,alias1,alias2,alias3 ssh-rsa ' + key)[:host_aliases]).to eq(['alias1', 'alias2', 'alias3'])
  end

  it 'does not drop an empty host_alias' do
    expect(subject.parse_line('test,alias, ssh-rsa ' + key)[:host_aliases]).to eq(['alias', ''])
  end

  it 'recognises when there are no host aliases' do
    expect(subject.parse_line('test ssh-rsa ' + key)[:host_aliases]).to eq([])
  end

  context 'with the sample file' do
    ['sample', 'sample_with_blank_lines'].each do |sample_file|
      let(:fixture) { my_fixture(sample_file) }

      before(:each) { allow(subject).to receive(:default_target).and_return(fixture) }

      it 'parses to records on prefetch' do
        expect(subject.target_records(fixture)).to be_empty
        subject.prefetch

        records = subject.target_records(fixture)
        expect(records).to be_an Array
        expect(records).to(be_all { |x| expect(x).to be_an(Hash) })
      end

      it 'reconstitutes the file from records' do
        subject.prefetch
        records = subject.target_records(fixture)
        text = subject.to_file(records).gsub(%r{^# HEADER.+\n}, '')

        oldlines = File.readlines(fixture).map(&:chomp)
        newlines = text.chomp.split("\n")
        expect(oldlines.length).to eq(newlines.length)

        oldlines.zip(newlines).each do |old, new|
          expect(old.gsub(%r{\s+}, '')).to eq(new.gsub(%r{\s+}, ''))
        end
      end
    end
  end

  context 'default ssh_known_hosts target path' do
    ['9.10', '9.11', '10.10'].each do |version|
      it 'is `/etc/ssh_known_hosts` when OSX version 10.10 or older`' do
        expect(Facter).to receive(:value).with(:operatingsystem).and_return('Darwin')
        expect(Facter).to receive(:value).with(:macosx_productversion_major).and_return(version)
        expect(subject.default_target).to eq('/etc/ssh_known_hosts')
      end
    end

    ['10.11', '10.13', '11.0', '11.11'].each do |version|
      it 'is `/etc/ssh/ssh_known_hosts` when OSX version 10.11 or newer`' do
        expect(Facter).to receive(:value).with(:operatingsystem).and_return('Darwin')
        expect(Facter).to receive(:value).with(:macosx_productversion_major).and_return(version)
        expect(subject.default_target).to eq('/etc/ssh/ssh_known_hosts')
      end
    end

    it 'is `/etc/ssh/ssh_known_hosts` on other operating systems' do
      expect(Facter).to receive(:value).with(:operatingsystem).and_return('RedHat')
      expect(subject.default_target).to eq('/etc/ssh/ssh_known_hosts')
    end
  end
end
