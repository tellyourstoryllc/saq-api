class RobotItem < ActiveRecord::Base
  def self.by_trigger(trigger)
    where(trigger: trigger).order(:rank)
  end
end
