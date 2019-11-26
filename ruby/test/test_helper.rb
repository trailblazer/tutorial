require "trailblazer/activity/dsl/linear"
require "minitest/autorun"

class User < Struct.new(:email, :id)
  class << self
    def init!(*rows)
      @rows = rows
    end
  end

  def self.find_by(email:)
    @rows.find { |row| row.email == email }
  end
end
