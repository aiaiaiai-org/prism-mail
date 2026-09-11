# © 2026 aiaiaiai · aiaiaiai.org

require_relative "test_helper"

class PrismMailTest < Minitest::Test
  def test_exposes_a_canonical_version
    assert_match(/\A\d+\.\d+\.\d+\.pre\.alpha\.\d+\z/, PrismMail::VERSION)
  end
end
