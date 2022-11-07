# frozen_string_literal: true

module DiscourseChatMatrix::MatrixEvents
  MATRIX_EVENT_REDIS_KEY_PREFIX = "matrix:ignore:matrix-event-"
  MATRIX_EVENT_REDIS_EXPIRY = 10.minutes

  def self.handlers(type)
    @handlers ||= {}
    @handlers[type] ||= []
  end

  def self.reset_handlers!
    # Used in testing environments
    @handlers = {}
  end

  def self.on(type, &block)
    handlers(type) << block
  end

  def self.call(event)
    handlers(event[:type]).each { |handler| handler.call(event) }
  end

  def self.ignore(event_id)
    Discourse.redis.setex(
      "#{MATRIX_EVENT_REDIS_KEY_PREFIX}-#{event_id}",
      MATRIX_EVENT_REDIS_EXPIRY,
      true,
    )
  end

  def self.ignored?(event_id)
    Discourse.redis.exists?("#{MATRIX_EVENT_REDIS_KEY_PREFIX}-#{event_id}")
  end
end
