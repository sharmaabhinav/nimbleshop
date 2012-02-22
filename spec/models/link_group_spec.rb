require 'spec_helper'

describe LinkGroup do
  describe "validations" do
    subject { create(:link_group) }
    it {
      must validate_presence_of(:name)
    }
  end
end
