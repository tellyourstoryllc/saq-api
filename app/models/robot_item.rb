class RobotItem < ActiveRecord::Base
  def triggers
    trigger.split(',')
  end

  def self.by_trigger(trigger)
    where("FIND_IN_SET(?, `trigger`)", trigger).order(:rank)
  end

  def self.valid_triggers
    @valid_triggers ||= all.map(&:triggers).flatten.uniq
  end
end
