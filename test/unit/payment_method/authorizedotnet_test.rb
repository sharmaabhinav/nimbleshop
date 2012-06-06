require "test_helper"

class PaymentMethodAuthorizeNetTest < ActiveSupport::TestCase

  test "validations" do
    pm = NimbleshopAuthorizedotnet::Authorizedotnet.new(name: 'Authorize.net', description: 'this is description')
    refute pm.valid?
    expected = ["Company name on creditcard statement can't be blank", "Login can't be blank", "Transaction key can't be blank"]
    assert_equal expected, pm.errors.full_messages.sort
  end

  test "should save the record" do
    pm = NimbleshopAuthorizedotnet::Authorizedotnet.new(name: 'Authorize.net', description: 'this is description')
    pm.login_id = 'FWERSDEED093d'
    pm.transaction_key = 'SDFSDFSFSF423433SDFSFSSFSFSF334'
    pm.company_name_on_creditcard_statement = 'BigBinary LLC'
    assert pm.save
    assert_match /authorize-net/, pm.permalink
  end

end