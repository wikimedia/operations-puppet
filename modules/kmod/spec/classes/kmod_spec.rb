require 'spec_helper'

describe 'kmod', :type => :class do

  on_supported_os.each do |os, facts|
    context "on #{os} with augeas 0.8.9" do
      let(:facts) do facts.merge({:augeasversion => '0.8.9'}) end
      it do
        expect {
          should compile
        }.to raise_error(/Augeas 0.10.0 or higher required/)
      end
    end
    context "on #{os}" do
      let(:facts) do
        facts.merge(  { :augeasversion => '1.2.0' } )
      end

      it { should contain_class('kmod') }
      it { should contain_file('/etc/modprobe.d').with({ 'ensure' => 'directory' }) }
      ['modprobe.conf','aliases.conf','blacklist.conf'].each do |file|
        it { should contain_file("/etc/modprobe.d/#{file}").with({ 'ensure' => 'file' }) }
      end
    end
  end
end
