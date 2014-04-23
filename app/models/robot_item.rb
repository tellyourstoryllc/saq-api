class RobotItem < ActiveRecord::Base
  def self.by_trigger(trigger)
    where(trigger: trigger).order(:rank)
  end

  def self.valid_triggers
    @valid_triggers ||= pluck('DISTINCT(`trigger`)')
  end
end
