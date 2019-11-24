require "test_helper"

require "test_helper"

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
    A
  end


end
