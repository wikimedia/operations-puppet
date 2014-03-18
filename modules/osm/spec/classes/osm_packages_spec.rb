require 'spec_helper'

describe 'osm::packages', :type => :class do
    let(:params) { {
        :ensure           => 'present',
        }
    }

    context 'ensure present' do
        it { should contain_package('osm2pgsql').with_ensure('present') }
        it { should contain_package('osmosis').with_ensure('present') }
    end
end

describe 'osm::packages', :type => :class do
    let(:params) { {
        :ensure           => 'absent',
        }
    }

    context 'ensure absent' do
        it { should contain_package('osm2pgsql').with_ensure('absent') }
        it { should contain_package('osmosis').with_ensure('absent') }
    end
end
