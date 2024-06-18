class EarningsClassifier
  ##
  # Calculates the earnings of a timesheet's shifts
  #

  attr_reader :timesheet

  def initialize(timesheet)
    @timesheet = timesheet
  end

  ##
  # Traverses a timesheet's shifts recording the earnings
  #
  def record!
    hours_rules_data = HoursRule.includes(:hours_rule_config,:earning_tests).all
    addon_rules_data = AddonRule.includes(:addon_rule_config).all

    hours_rules = hours_rules_data.sort_by { |rule| -(rule.hours_rule_config.rank || 0) }
    addon_rules = addon_rules_data.sort_by { |rule| -(rule.addon_rule_config.units || 0) }

    max_hour_configs = MaximumHoursTestConfig.pluck(:maximum_hours_test_id, :threshold, :period)
    max_hour_config_hash = max_hour_configs.each_with_object({}) do |(id, threshold, period), hash|
      hash[id] = { :threshold => threshold, :period => period }
    end

    sheet_hours = 0

    timesheet.shifts.includes(:earnings).each_with_object(EarningsContext.new) do |shift, ctx|
      shift.earnings.destroy_all

      ctx.next!(shift)
      sheet_hours += ctx.remaining_hours

      hours_rules.each do |rule|
        break unless ctx.remaining_hours?
          applicable_hours = ctx.remaining_hours
          config = max_hour_config_hash.fetch(rule.earning_tests&.first&.id,:undef )
          period = ""

          if (config != :undef)
            threshold = config[:threshold]
            period = config[:period]
            applicable_hours = (ctx.shift_hours - threshold).clamp(0, ctx.remaining_hours)
          end

          if (period == "hours_of_day")
            applicable_hours = hours_on_day_in_period(shift.start, shift.finish, threshold)
          end

          if (period == "timesheet")
            applicable_hours = sheet_hours - threshold
          end

          next if applicable_hours <= 0

          shift.earnings.build(earning_rule: rule, units: applicable_hours)
          ctx.apply!(applicable_hours)
         end

      addon_rules.each do |rule|
        shift.earnings.build(earning_rule: rule, units: rule.units) if rule.addon?(ctx)
      end

      shift.save!
    end
  end

  ##
  # count hours of day given by int in given interval defined by start_time and end_time
  # return 0 if none
  def hours_on_day_in_period(start_time, end_time, day_of_week)
    hours_on_day = 0
    current_time = start_time

    while current_time < end_time
      hours_on_day += 1 if current_time.wday == day_of_week
      current_time += 1.hour
    end

    hours_on_day
  end

end
