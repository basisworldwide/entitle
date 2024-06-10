class EmployeeIntegration < ApplicationRecord
  belongs_to :employee
  belongs_to :integration
  attr_accessor :is_permission_assigned, :is_integration_deleted
end
