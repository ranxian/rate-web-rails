require "test_helper"

class ManagerTest < ActiveSupport::TestCase

  def manager
    @manager ||= Manager.new
  end

  def test_valid
    assert manager.valid?
  end

end
