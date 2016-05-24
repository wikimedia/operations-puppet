require 'spec_helper'

describe 'nrpe::check_disk', :type => :define do
  let(:title) { 'default' }

  context 'with default params' do
    it 'should use default configuration' do
      should contain_nrpe__monitor_service('disk_space-default').with(
          :description  => 'Disk space default',
          :critical     => false,
          :nrpe_command => '/usr/lib/nagios/plugins/check_disk -w 6% -c 3% -l -e -all --ignore-ereg-path="/srv/sd[a-b][1-3]" --exclude-type=tracefs',
          :retries      => 3,
      )
    end
  end

  context 'with no ignored path' do
    let(:params) { { :ignore_ereg_path => [] } }
    it 'should not contain --ignore-ereg-path' do
      should contain_nrpe__monitor_service('disk_space-default').with(
          :nrpe_command => '/usr/lib/nagios/plugins/check_disk -w 6% -c 3% -l -e -all --exclude-type=tracefs',
      )
    end
  end

  context 'with no excluded fs types' do
    let(:params) { { :exclude_types => [] } }
    it 'should not contain --exclude-type' do
      should contain_nrpe__monitor_service('disk_space-default').with(
          :nrpe_command => '/usr/lib/nagios/plugins/check_disk -w 6% -c 3% -l -e -all --ignore-ereg-path="/srv/sd[a-b][1-3]"',
      )
    end
  end

  context 'with path defined' do
    let(:params) { {
        :paths => [ '/some/path' ],
        :exclude_types => [],
        :ignore_ereg_path => [],
    } }
    it 'should not contain --exclude-type' do
      should contain_nrpe__monitor_service('disk_space-default').with(
          :nrpe_command => '/usr/lib/nagios/plugins/check_disk -w 6% -c 3% -l -e -all --path=/some/path',
      )
    end
  end

  context 'with options defined' do
    let(:params) { {
        :options => 'some options',
    } }
    it 'should ignore other parameters' do
      should contain_nrpe__monitor_service('disk_space-default').with(
          :nrpe_command => '/usr/lib/nagios/plugins/check_disk some options',
      )
    end
  end


end
