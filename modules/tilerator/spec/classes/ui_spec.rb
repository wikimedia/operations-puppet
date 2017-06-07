require 'spec_helper'

describe 'tilerator::ui', :type => :class do
  context 'with default parameters' do
    # there is an issue with secret() that is a transitive dependency of service::node
    # not sure how to fix it...
    xit { is_expected.to contain_file('/usr/local/bin/notify-tilerator')
                            .with_mode('0555')
                            .with_content(/-j.deleteEmpty \\/)
    }
  end

  context 'with delete_empty => false' do
    let(:params) { {:delete_empty => false} }
    # there is an issue with secret() that is a transitive dependency of service::node
    # not sure how to fix it...
    xit { is_expected.to contain_file('/usr/local/bin/notify-tilerator')
                             .with_mode('0555')
                            .without_content(/-j.deleteEmpty/)
    }
  end
end
