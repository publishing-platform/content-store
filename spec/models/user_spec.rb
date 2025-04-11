require "rails_helper"
require "publishing_platform_sso/lint/user_spec"

RSpec.describe User, type: :model do
  it_behaves_like "a publishing_platform_sso user class"
end
