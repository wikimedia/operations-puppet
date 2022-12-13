require 'spec_helper'

describe 'Postfix::Type::Lookup::Database::Flat' do
  it { is_expected.to allow_values('texthash', 'cidr', 'pcre', 'regexp') }
  it { is_expected.not_to allow_value('invalid') }
end
