class RobotItem < ActiveRecord::Base
  def triggers
    trigger.split(',')
  end

  def text
    if self[:text].include?('%max_help_number%')
      self[:text].gsub('%max_help_number%', self.class.max_help_number)
    else
      self[:text]
    end
  end

  def self.max_help_number
    valid_triggers.select{ |t| t =~ /^\d+$/ }.max{ |t| t.to_i }
  end

  def self.by_trigger(trigger)
    where("FIND_IN_SET(?, `trigger`)", trigger).order(:rank)
  end

  def self.valid_triggers
    @valid_triggers ||= all.map(&:triggers).flatten.uniq
  end
end
