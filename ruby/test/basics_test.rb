require "test_helper"

Trailblazer::Activity::Railway.class_eval do
  def self.invoke(*args)
    Trailblazer::Activity::TaskWrap.invoke(self, *args)
  end
end

class BasicsTest < Minitest::Spec
  module A
    User = Module.new

    #:rw
    class Signup < Trailblazer::Activity::Railway
      step :validate
      pass :extract_omniauth
      step :find_user
      pass :log
    end
    #:rw end
  end

=begin
#:controller
def auth
  # at this stage, we're already authenticated, it's a valid Github user!
  result = Signup.call(params: params)
end
#:controller end

#:omniauth
{
 :provider=>"github",
 :info=>{
  :nickname=>"apotonick",
  :email=>"apotonick@gmail.com",
  :name=>"Nick Sutterer"
 }
}
#:omniauth end
=end


  it do
    Signup = A::Signup
    #:invoke
    ctx = {params: {provider: "Nickhub"}}

    signal, (ctx, _) = Signup.invoke([ctx], {})
    #:invoke end
    puts signal
  end

=begin
#:name-error
NameError: undefined method `validate' for class `Signup'
#:name-error end
=end

  module B
    #:rw-meth
    class Signup < Trailblazer::Activity::Railway
      step :validate
      pass :extract_omniauth
      step :find_user
      pass :log

      # Validate the incoming Github data.
      # Yes, we could and should use Reform or Dry-validation here.
      #:rw-validate
      def validate(ctx, params:, **)
        params.is_a?(Hash) && params["info"].is_a?(Hash) && params["info"]["email"]
      end
      #:rw-validate end

      #~extr
      def extract_omniauth(ctx, params:, **)
        ctx[:email] = params["info"]["email"]
      end

      def find_user(ctx, email:, **)
        user = User.find_by(email: email)

        ctx[:user] = user
      end

      def log(ctx, **)
        # run some logging here
      end
      #~extr end
    end
    #:rw-meth end

    module BB
      class Signup < Trailblazer::Activity::Railway
        step :validate

        #:rw-raise
        def validate(ctx, params:, **)
          raise ctx.inspect
        end
        #:rw-raise end
      end
    end
  end
=begin
#:exc
ctx = {params: {provider: "Nickhub"}}

signal, (ctx, _) = Signup.invoke([ctx], {})
#=> RuntimeError: {:params=>{:provider=>"Nickhub"}}
#:exc end
=end

  it do
    ctx = {params: {provider: "Nickhub"}}

    B::BB::Signup.invoke([ctx], {})
  end
end
