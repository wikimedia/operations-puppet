require 'spec_helper'

describe 'postgresql::postgis', :type => :class do
    let(:facts) { { :lsbdistcodename => 'jessie' } }
    let(:params) { {
        :ensure => 'present',
        }
    }

    context 'ensure present' do
        it { should contain_package('postgresql-9.4-postgis-2.3').with_ensure('present') }
    end
end
