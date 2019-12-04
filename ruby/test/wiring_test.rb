require "test_helper"

class WiringTest < Minitest::Spec
  let(:data_from_github) {
    data_from_github = {
     "provider"=>"github",
     "info"=>{
      "nickname"=>"apotonick",
      "email"=>"apotonick@gmail.com",
      "name"=>"Nick Sutterer"
     }
    }
  }

  module A
    #:fail-id
    class Signup < Trailblazer::Activity::Railway
      step :validate
      pass :extract_omniauth
      step :find_user
      fail :create_user, Output(:success) => Id(:log)
      pass :log

      def create_user(ctx, email:, **)
        ctx[:user] = User.create(email: email)
      end
      #~tasks
      def validate(ctx, params:, **)
        is_valid = params.is_a?(Hash) && params["info"].is_a?(Hash) && params["info"]["email"]

        is_valid # return value matters!
      end

      def extract_omniauth(ctx, params:, **)
        ctx[:email] = params["info"]["email"]
      end

      #:rw-find
      def find_user(ctx, email:, **)
        user = User.find_by(email: email)

        ctx[:user] = user
      end
      #:rw-find end

      def log(ctx, **)
        # run some logging here
      end
      #~tasks end
    end
    #:fail-id end
  end

  it "what" do
    Signup = A::Signup

    # User.init!(User.new("apotonick@gmail.com"))
    User.init!()

    ctx = {params: data_from_github}

    #:rw-invocation
    signal, (ctx, _) = Trailblazer::Developer.wtf?(Signup, [ctx])
    #:rw-invocation end

    signal.inspect.must_equal %{#<Trailblazer::Activity::End semantic=:success>}
    ctx[:user].inspect.must_equal %{#<struct User email=\"apotonick@gmail.com\", id=nil>}
  end

  module B
    #:fail-itrack
    class Signup < Trailblazer::Activity::Railway
      step :validate
      pass :extract_omniauth
      step :find_user
      fail :create_user, Output(:success) => Track(:success)
      pass :log

      def create_user(ctx, email:, **)
        ctx[:user] = User.create(email: email)
      end
      #~tasks
      def validate(ctx, params:, **)
        is_valid = params.is_a?(Hash) && params["info"].is_a?(Hash) && params["info"]["email"]

        is_valid # return value matters!
      end

      def extract_omniauth(ctx, params:, **)
        ctx[:email] = params["info"]["email"]
      end

      #:rw-find
      def find_user(ctx, email:, **)
        user = User.find_by(email: email)

        ctx[:user] = user
      end
      #:rw-find end

      def log(ctx, **)
        # run some logging here
      end
      #~tasks end
    end
    #:fail-track end
  end

  it "Track()" do
    Signup = B::Signup

    # User.init!(User.new("apotonick@gmail.com"))
    User.init!()

    ctx = {params: data_from_github}

    #:rw-invocation
    signal, (ctx, _) = Trailblazer::Developer.wtf?(Signup, [ctx])
    #:rw-invocation end

    signal.inspect.must_equal %{#<Trailblazer::Activity::End semantic=:success>}
    ctx[:user].inspect.must_equal %{#<struct User email=\"apotonick@gmail.com\", id=nil>}
  end
end
