class HoursRule < EarningRule
  ##
  # Delegates a shift's hours as a type of compensation
  #

  has_one :hours_rule_config
  delegate :rank, to: :hours_rule_config

  def self.fetch_sorted
    includes(:hour_rule_config).order('hour_rule_configs.rank DESC')
  end

  ##
  # An hours rule applies to the minimum hours
  # applicable to a test.
  #
  def hours(ctx)
    return ctx.shift_hours if earning_tests.none?

    earning_tests.map { |test| test.hours(ctx) }.min
  end
end

