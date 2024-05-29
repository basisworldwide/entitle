module ActivityLogConcern
  extend ActiveSupport::Concern

  included do
    # Add shared instance methods here
    # Example:
    # has_secure_password

    def store_activity_log(employee_id,created_by,description)
      activity_log = ActivityLog.new
      activity_log[:employee_id] = employee_id
      activity_log[:created_by] = created_by
      activity_log[:description] = description
      activity_log.save!
    end
  end
  class_methods do
    # Add shared class methods here
  end

end