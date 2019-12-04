require "trailblazer/activity/dsl/linear"
require "trailblazer/developer"

require "minitest/autorun"

class User < Struct.new(:email, :id)
  class << self
    def init!(*rows)
      @rows = rows
    end

    def create(email:)
      new(email)
    end
  end

  def self.find_by(email:)
    @rows.find { |row| row.email == email }
  end
end
