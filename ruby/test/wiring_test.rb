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

    #:fail-wtf
    User.init!()

    ctx = {params: data_from_github}

    signal, (ctx, _) = Trailblazer::Developer.wtf?(Signup, [ctx])
    #:fail-wtf end

    signal.inspect.must_equal %{#<Trailblazer::Activity::End semantic=:success>}
    ctx[:user].inspect.must_equal %{#<struct User email=\"apotonick@gmail.com\", id=nil, username=nil>}

    #:render
    puts Trailblazer::Developer.render(Signup)
    #:render end
  end

  module B
    #:fail-track
    class Signup < Trailblazer::Activity::Railway
      step :validate
      pass :extract_omniauth
      step :find_user
      fail :create_user, Output(:success) => Track(:success)
      pass :log

      #~tasks
      def create_user(ctx, email:, **)
        ctx[:user] = User.create(email: email)
      end
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
    ctx[:user].inspect.must_equal %{#<struct User email=\"apotonick@gmail.com\", id=nil, username=nil>}
  end

  module C
    #:output
    class Signup < Trailblazer::Activity::Railway
      NewUser = Class.new(Trailblazer::Activity::Signal)

      step :validate
      pass :extract_omniauth
      #:track
      step :find_user, Output(NewUser, :new) => Track(:create)
      step :create_user, Output(:success) => End(:new), magnetic_to: :create
      #:track end
      pass :log

      #~tasks
      def create_user(ctx, email:, **)
        ctx[:user] = User.create(email: email)
      end

      def validate(ctx, params:, **)
        is_valid = params.is_a?(Hash) && params["info"].is_a?(Hash) && params["info"]["email"]

        is_valid # return value matters!
      end

      def extract_omniauth(ctx, params:, **)
        ctx[:email] = params["info"]["email"]
      end

      #:find-signal
      def find_user(ctx, email:, **)
        user = User.find_by(email: email)

        ctx[:user] = user

        user ? true : NewUser
      end
      #:find-signal end

      def log(ctx, **)
        # run some logging here
      end
      #~tasks end
    end
    #:output end
  end

  it "Output()" do
    Signup = C::Signup

# New user
    User.init!()

    ctx = {params: data_from_github}

    #:new
    signal, (ctx, _) = Trailblazer::Developer.wtf?(Signup, [ctx])
    #:new end

    signal.inspect.must_equal %{#<Trailblazer::Activity::End semantic=:new>}
    ctx[:user].inspect.must_equal %{#<struct User email=\"apotonick@gmail.com\", id=nil, username=nil>}

# Existing user
    User.init!(User.new("apotonick@gmail.com", 1))

    ctx = {params: data_from_github}

    #:success
    signal, (ctx, _) = Trailblazer::Developer.wtf?(Signup, [ctx])
    #:success end

    signal.inspect.must_equal %{#<Trailblazer::Activity::End semantic=:success>}
    ctx[:user].inspect.must_equal %{#<struct User email=\"apotonick@gmail.com\", id=1, username=nil>}
  end

  module D
    #:path
    class Signup < Trailblazer::Activity::Railway
      NewUser = Class.new(Trailblazer::Activity::Signal)

      step :validate
      pass :extract_omniauth
      step :find_user, Output(NewUser, :new) => Path(end_id: "End.new", end_task: End(:new)) do
        step :compute_username
        step :create_user
        step :notify
      end
      pass :log

      #~tasks
      def create_user(ctx, email:, **)
        ctx[:user] = User.create(email: email)
      end

      def validate(ctx, params:, **)
        is_valid = params.is_a?(Hash) && params["info"].is_a?(Hash) && params["info"]["email"]

        is_valid # return value matters!
      end

      def extract_omniauth(ctx, params:, **)
        ctx[:email] = params["info"]["email"]
      end

      def find_user(ctx, email:, **)
        user = User.find_by(email: email)

        ctx[:user] = user

        user ? true : NewUser
      end

      def log(ctx, **)
        # run some logging here
      end

      #:path-tasks
      def compute_username(ctx, email:, **)
        ctx[:username] = email.split("@")[0]
      end

      def create_user(ctx, email:, username:, **)
        ctx[:user] = User.create(email: email, username: username)
      end

      def notify(ctx, **)
        true
      end
      #:path-tasks end
      #~tasks end
    end
    #:path end
  end

  it "Path()" do
    Signup = D::Signup

# New user
    #:path-new
    User.init!()
    ctx = {params: data_from_github}

    signal, (ctx, _) = Trailblazer::Developer.wtf?(Signup, [ctx])

    signal.to_h[:semantic] #=> :new
    ctx[:user]             #=> #<User email=\"apotonick@gmail.com\", username=\"apotonick\">
    #:path-new end

    signal.inspect.must_equal %{#<Trailblazer::Activity::End semantic=:new>}
    ctx[:user].inspect.must_equal %{#<struct User email=\"apotonick@gmail.com\", id=nil, username=\"apotonick\">}

# Existing user
    #:path-existing
    User.init!(User.new("apotonick@gmail.com", 1, "apotonick"))
    ctx = {params: data_from_github}

    signal, (ctx, _) = Trailblazer::Developer.wtf?(Signup, [ctx])

    signal.to_h[:semantic] #=> :success
    ctx[:user]             #=> #<User email=\"apotonick@gmail.com\", username=\"apotonick\">
    #:path-existing end

    signal.inspect.must_equal %{#<Trailblazer::Activity::End semantic=:success>}
    ctx[:user].inspect.must_equal %{#<struct User email=\"apotonick@gmail.com\", id=1, username=\"apotonick\">}
  end

  module E
    #:compute_username
    class Signup < Trailblazer::Activity::Railway
      NewUser = Class.new(Trailblazer::Activity::Signal)

      step :validate
      pass :extract_omniauth
      step :find_user, Output(NewUser, :new) => Path(end_id: "End.new", end_task: End(:new)) do
        step :compute_username, Trailblazer::Activity.Output(Trailblazer::Activity::Left, :failure) => Trailblazer::Activity::DSL::Linear.Track(:failure)
        step :create_user
        step :notify
      end
      pass :log

      #~tasks
      def validate(ctx, params:, **)
        is_valid = params.is_a?(Hash) && params["info"].is_a?(Hash) && params["info"]["email"]

        is_valid # return value matters!
      end

      def extract_omniauth(ctx, params:, **)
        ctx[:email] = params["info"]["email"]
      end

      def find_user(ctx, email:, **)
        user = User.find_by(email: email)

        ctx[:user] = user

        user ? true : NewUser
      end

      #:compute_username_false
      def compute_username(ctx, email:, **)
        false
      end
      #:compute_username_false end
      #~tasks end
    end
    #:compute_username end
  end

  it "Path() escape" do
    Signup = E::Signup

# Break and escape in {compute_username}
    User.init!()

    ctx = {params: data_from_github}

    signal, (ctx, _) = Trailblazer::Developer.wtf?(Signup, [ctx])

    signal.inspect.must_equal %{#<Trailblazer::Activity::End semantic=:failure>}
    ctx[:user].inspect.must_equal %{nil}
  end
end
