require "test_helper"

Trailblazer::Activity::Railway.class_eval do
  def self.invoke(*args)
    Trailblazer::Activity::TaskWrap.invoke(self, *args)
  end
end

class BasicsTest < Minitest::Spec
  module A
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

      #~tasks
      # Validate the incoming Github data.
      # Yes, we could and should use Reform or Dry-validation here.
      #:rw-validate
      def validate(ctx, params:, **)
        is_valid = params.is_a?(Hash) && params["info"].is_a?(Hash) && params["info"]["email"]

        is_valid # return value matters!
      end
      #:rw-validate end

      #~extr
      #:rw-extract
      def extract_omniauth(ctx, params:, **)
        ctx[:email] = params["info"]["email"]
      end
      #:rw-extract end

      #:rw-find
      def find_user(ctx, email:, **)
        user = User.find_by(email: email)

        ctx[:user] = user
      end
      #:rw-find end

      #:rw-log
      def log(ctx, **)
        # run some logging here
      end
      #:rw-log end
      #~extr end
      #~tasks end
    end
    #:rw-meth end

    module BB
      class Signup < Trailblazer::Activity::Railway
        step :validate

        #:rw-params
        def validate(ctx, params:, **)
          raise params.inspect
        end
        #:rw-params end

        #:rw-ctx
        def validate(ctx, **)
          params = ctx[:params] # no keyword argument used!
          raise params.inspect
        end
        #:rw-ctx end
      end
    end
  end
=begin
#:exc-params
ctx = {params: {provider: "Nickhub"}}

signal, (ctx, _) = Signup.invoke([ctx], {})

#=> RuntimeError: {:provider=>"Nickhub"}
#:exc-params end

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

  it "plays" do
    Signup = B::Signup

    #:rw-invocation-setup
    data_from_github = {
     "provider"=>"github",
     "info"=>{
      "nickname"=>"apotonick",
      "email"=>"apotonick@gmail.com",
      "name"=>"Nick Sutterer"
     }
    }

    ctx = {params: data_from_github}
    #:rw-invocation-setup end

    User.init!

    signal, (ctx, _) = Signup.invoke([ctx], {})

    signal.inspect.must_equal %{#<Trailblazer::Activity::End semantic=:failure>}
    ctx[:user].inspect.must_equal "nil"

=begin
#:rw-invocation-fail
User.init! # Empty users table.

signal, (ctx, _) = Signup.invoke([ctx], {})

puts signal     #=> #<Trailblazer::Activity::End semantic=:failure>
puts ctx[:user] #=> nil
#:rw-invocation-fail end
=end



    User.init!(User.new("apotonick@gmail.com"))

    #:rw-invocation
    signal, (ctx, _) = Signup.invoke([ctx], {})
    #:rw-invocation end

    signal.inspect.must_equal %{#<Trailblazer::Activity::End semantic=:success>}
    ctx[:user].inspect.must_equal %{#<struct User email=\"apotonick@gmail.com\", id=nil, username=nil>}

    #:ctx-read
    ctx[:user] #=> #<struct User email=\"apotonick@gmail.com\">
    #:ctx-read end

    signal.to_h[:semantic].must_equal :success

    Trailblazer::Activity::Introspect::Graph(Signup).find("End.success")[:task].must_equal signal
    #:end-find
    Trailblazer::Activity::Introspect::Graph(Signup).find("End.success")[:task] == signal
    #:end-find end

=begin
#:rw-invocation-success
User.init!(User.new("apotonick@gmail.com"))

signal, (ctx, _) = Signup.invoke([ctx], {})

puts signal     #=> #<Trailblazer::Activity::End semantic=:success>
puts ctx[:user] #=> #<User email: "apotonick@gmail.com">
#:rw-invocation-success end

#:end-semantic
signal.to_h[:semantic] #=> :success
#:end-semantic end
=end

    ctx = {params: data_from_github}

    #:wtf
    signal, (ctx, _) = Trailblazer::Developer.wtf?(Signup, ctx)
    #:wtf end

    #:wtf-exception
    ctx = {params: data_from_github}.freeze #=> no setter anymore!

    signal, (ctx, _) = Trailblazer::Developer.wtf?(Signup, ctx)
    #:wtf-exception end
  end

    module C
      module Logger
        def self.info(*args)

        end
      end

      #:fail
      class Signup < Trailblazer::Activity::Railway
        step :validate
        pass :extract_omniauth
        fail :save_validation_data
        step :find_user
        pass :log
        #~tasks
        def validate(ctx, **)
          false
        end
        #~tasks end

        def save_validation_data(ctx, params:, **)
          Logger.info "Signup: params was #{params.inspect}"
        end
      end
      #:fail end
    end

  it do
    ctx = {params: {}}

    signal, (ctx, _) = Trailblazer::Developer.wtf?(C::Signup, ctx)
    signal.inspect.must_equal %{#<Trailblazer::Activity::End semantic=:failure>}
  end
end
