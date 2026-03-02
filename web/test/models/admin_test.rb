require "test_helper"

class AdminTest < ActiveSupport::TestCase
  test "validates presence of username" do
    admin = Admin.new(password: "test1234")
    assert_not admin.valid?
    assert_includes admin.errors[:username], "can't be blank"
  end

  test "validates uniqueness of username" do
    admin = Admin.new(username: admins(:one).username, password: "test1234")
    assert_not admin.valid?
    assert_includes admin.errors[:username], "has already been taken"
  end

  test "has_secure_password authenticates correctly" do
    admin = Admin.create!(username: "testuser", password: "secret123")
    assert admin.authenticate("secret123")
    assert_not admin.authenticate("wrong")
  end
end
