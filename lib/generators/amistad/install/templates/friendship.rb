class Friendship < ActiveRecord::Base
  include Amistad::FriendshipModel
  
  # # Uncomment the below lines if you require reasons or greetings with your friend requests
  #
  # validates_presence_of :reason
  # validate do
  #   errors.add_to_base("Requests can only be sent to people you know personally.") if reason == 'dontKnow'
  # end
  #
  # # Return the reasons array for the invite form
  # def self.reasons(name = nil)
  #   [
  #     "Classmates", 
  #     "Friends", 
  #     ["I don't know #{name}", "dontKnow"]
  #   ]
  # end
end
