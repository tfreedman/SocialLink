# lib/slow_query_logger.rb

require "json"
require "digest"
require "logger"

class SlowQueryLogger
  def initialize(output = nil, opts = {})
    # will log any query slower than 500 ms
    @threshold = opts.fetch(:threshold, "500").to_i

    @logger = Logger.new(output || STDOUT)
    @logger.formatter = method(:formatter)
  end

  def call(name, start, finish, id, payload)
    # Skip transaction start/end statements
    return if payload[:sql].match(/BEGIN|COMMIT/)

    duration = ((finish - start) * 1000).round(4)
    return unless duration >= @threshold

    data = {
      time:       start.iso8601,
      pid:        Process.pid,
      pname:      $PROGRAM_NAME,
      duration:   duration,
      query:      payload[:sql].strip.gsub(/(^([\s]+)?$\n)/, ""),
      kind:       payload[:sql].match(/INSERT|UPDATE|DELETE/) ? "write" : "read",
      length:     payload[:sql].size,
      cached:     payload[:cache] ? true : false,
      hash:       Digest::SHA1.hexdigest(payload[:sql])
    }.compact

    @logger.info(data)
  end

  private

  def formatter(severity, time, progname, data)
    JSON.dump(data) + "\n"
  end
end
