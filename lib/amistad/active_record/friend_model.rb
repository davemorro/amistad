module Amistad
  module ActiveRecord
    module FriendModel
      def self.included(receiver)
        receiver.class_exec do
          include InstanceMethods

          has_many  :friendships
        
          has_many  :pending_friendship_requested,
            :through => :friendships,
            :source => :friend,
            :conditions => { :'friendships.pending' => true, :'friendships.blocker_id' => nil }
          
          has_many  :friendship_requested,
            :through => :friendships,
            :source => :friend,
            :conditions => { :'friendships.pending' => false, :'friendships.blocker_id' => nil }
          
          has_many  :inverse_friendships, :class_name => "Friendship", :foreign_key => "friend_id"
          
          has_many  :pending_friendship_requested_by,
            :through => :inverse_friendships,
            :source => :user,
            :conditions => { :'friendships.pending' => true, :'friendships.blocker_id' => nil }
          
          has_many  :friendship_requested_by,
            :through => :inverse_friendships,
            :source => :user,
            :conditions => { :'friendships.pending' => false, :'friendships.blocker_id' => nil }
          
          has_many  :blocked_friendships, :class_name => "Friendship", :foreign_key => "blocker_id"
          
          has_many  :blockades,
            :through => :blocked_friendships,
            :source => :friend,
            :conditions => "friend_id <> blocker_id"
          
          has_many  :blockades_by,
            :through => :blocked_friendships,
            :source => :user,
            :conditions => "user_id <> blocker_id"
        end
      end

      module InstanceMethods
        # suggest a user to become a friend. If the operation succeeds, the method returns true, else false
        def request_friendship(user, reason = nil, greeting = nil)
          return false if user == self || find_any_friendship_with(user)
          Friendship.new(:user_id => self.id, :friend_id => user.id, :reason => reason, :greeting => greeting).save
        end
        
        # approve a friendship invitation. If the operation succeeds, the method returns true, else false
        def approve_friendship(user)
          friendship = find_any_friendship_with(user)
          return false if friendship.nil? || friendship_requested?(user)
          friendship.approve
        end
        
        # deletes a friendship
        def remove_friendship(user)
          friendship = find_any_friendship_with(user)
          return false if friendship.nil?
          friendship.destroy && friendship.destroyed?
        end
        
        # returns the list of approved friends
        def friends
          self.friendship_requested(true) + self.friendship_requested_by(true)
        end
        
        # total # of friendship_requested and friendship_requested_by without association loading
        def total_friends
          self.friendship_requested(false).count + self.friendship_requested_by(false).count
        end
        
        # blocks a friendship
        def block_friend(user)
          friendship = find_any_friendship_with(user)
          return false if friendship.nil? || !friendship.can_block?(self)
          friendship.block
        end
        
        # unblocks a friendship
        def unblock_friend(user)
          friendship = find_any_friendship_with(user)
          return false if friendship.nil? || !friendship.can_unblock?(self)
          friendship.unblock
        end
        
        # returns the list of blocked friends
        def blocked_friends
          self.blockades(true) + self.blockades_by(true)
        end
        
        # total # of blockades and blockedes_by without association loading
        def total_blocked_friends
          self.blockades(false).count + self.blockades_by(false).count
        end
        
        # checks if a user is blocked
        def friend_blocked?(user)
          blocked.include?(user)
        end
        
        # checks if a user is a friend
        def friend_with?(user)
          friends.include?(user)
        end
        
        def pending_friendship_with?(user)
          connected_with?(user) && !friend_with?(user)
        end
        
        # checks if a current user is connected to given user
        def connected_with?(user)
          find_any_friendship_with(user).present?
        end
        
        # checks if a current user received invitation from given user
        def friendship_requested_by?(user)
          friendship = find_any_friendship_with(user)
          return false if friendship.nil?
          friendship.user == user
        end
        
        # checks if a current user invited given user
        def friendship_requested?(user)
          friendship = find_any_friendship_with(user)
          return false if friendship.nil?
          friendship.friend == user
        end
        
        # return the list of the ones among its friends which are also friend with the given use
        def common_friends_with(user)
          self.friends & user.friends
        end
        
        # returns friendship with given user or nil
        def find_any_friendship_with(user)
          friendship = Friendship.where(:user_id => self.id, :friend_id => user.id).first
          if friendship.nil?
            friendship = Friendship.where(:user_id => user.id, :friend_id => self.id).first
          end
          friendship
        end
      end    
    end
  end
end
