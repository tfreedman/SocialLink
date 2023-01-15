if true # ENV["RAILS_LOG_SLOW_QUERIES"] == "1"
  require "slow_query_logger"

  # Setup the logger
  output = Rails.root.join("log/slow_queries.log")
  logger = SlowQueryLogger.new(output, threshold: 500) #ENV["RAILS_LOG_SLOW_QUERIES_THRESHOLD"])

  # Subscribe to notifications
  ActiveSupport::Notifications.subscribe("sql.active_record", logger)
end
