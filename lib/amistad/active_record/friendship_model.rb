module Amistad
  module ActiveRecord
    module FriendshipModel
      def self.included(receiver)
        receiver.class_exec do
          include InstanceMethods

          belongs_to :user
          belongs_to :friend, :class_name => "User", :foreign_key => "friend_id"
          belongs_to :blocker, :class_name => "User", :foreign_key => "blocker_id"

          validates_presence_of :user_id, :friend_id
          validates_uniqueness_of :friend_id, :scope => :user_id
        end
      end

      module InstanceMethods
        # returns true if a friendship has been approved, else false
        def approved?
          !self.pending
        end

        # returns true if a friendship has not been approved, else false
        def pending?
          self.pending
        end

        # returns true if a friendship has been blocked, else false
        def blocked?
          self.blocker_id.present?
        end

        # returns true if a friendship has not beed blocked, else false
        def active?
          self.blocker_id.nil?
        end

        # returns true if a friendship can be blocked by given user
        def can_block?(user)
          active? && (approved? || (pending? && self.friend == user))
        end

        # returns true if a friendship can be unblocked by given user
        def can_unblock?(user)
          blocked? && self.blocker == user
        end
        
        def approve
          notify_observers :before_approve
          if self.update_attribute(:pending, false)
            notify_observers :after_approve
            true
          else
            false
          end
        end
        
        def block
          notify_observers :before_block
          if self.friendship.update_attribute(:blocker, friend)
            notify_observers :after_block
            true
          else
            false
          end
        end
        
        def unblock
          notify_observers :before_unblock
          if self.friendship.update_attribute(:blocker, nil)
            notify_observers :after_unblock
            true
          else
            false
          end
        end
        
      end
    end
  end
end
