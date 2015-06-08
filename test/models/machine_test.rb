require "test_helper"

class MachineTest < ActiveSupport::TestCase

  def machine
    @machine ||= Machine.new
  end

  def test_valid
    assert machine.valid?
  end

end
