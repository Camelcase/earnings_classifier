class MaximumHoursTestConfig < ApplicationRecord
  ##
  # Contains the configuration of a maximum hours test
  #

  enum period: { shift: "shift", timesheet: "timesheet", hours_of_day: "hours_of_day" }
  belongs_to :maximum_hours_test
  validates :period, presence: true
  validates :threshold, presence: true
end
