# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# create company
if Company.count == 0
  Company.create!([{
    name: "75Way technologies"
  }])
  p "Created #{Company.count} company"  
end

# Create roles
if Role.count == 0
  Role.create!([{
    name: "ADMIN"
  },
  {
    name: "STAFF"
  }])
  p "Created #{Role.count} roles"  
end

# 
if Integration.count == 0
  Integration.create!([{
      name: "Slack",
      description: "Free cloud-based web service that provides a suite of collaboration tools and services.",
      logo: ""
    },
    {
      name: "Github",
      description: "Hosting website designed for programming projects using the Git version control system.",
      logo: ""

    },
    {
      name: "Outlook365",
      description: "Collaboration and cloud-based services owned by Microsoft",
      logo: ""
    },
    {
      name: "AWS",
      description: "Provides on-demand cloud computing platforms and APIs.",
      logo: ""
    },
    {
      name: "Google Workspace",
      description: "Free collaboration and productivity apps for businesses of all sizes.",
      logo: ""
    },
    {
      name: "Quickbooks",
      description: "Designed to help you manage your business finances with ease.",
      logo: ""
    },
    {
      name: "Deel",
      description: "Provides hiring and payments services for companies hiring international employees.",
      logo: ""
    },
    {
      name: "Trinet",
      description: "Provides with HR solutions including payroll, benefits, risk management and compliance",
      logo: ""
    }
  ])
  p "Created #{Integration.count} integration"  
end
user = User.find_by(email:  "lbansal.75way@gmail.com")
if user.blank?
  @company = Company.find_by(name: "75Way technologies");
  @role = Role.find_by(name: "ADMIN");
  User.create!([
    {
      email: "lbansal.75way@gmail.com",
      password: "75way!234",
      password_confirmation: "75way!234",
      name: "Lokesh",
      phone: "1478952630",
      joining_date: "2020-01-01",
      company_id: @company&.id,
      role_id: @role&.id
    }
  ])
end