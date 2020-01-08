require 'spec_helper'

describe 'postgresql::postgis', :type => :class do
    let(:facts) do
      {
        'lsbdistcodename' => 'jessie',
        'lsbdistrelease' => '8.6',
        'lsbdistid' => 'Debian'
      }
    end

    let(:params) { {
        :ensure => 'present',
        }
    }

    context 'ensure present' do
        it { should contain_package('postgresql-9.4-postgis-2.3').with_ensure('present') }
    end
end
