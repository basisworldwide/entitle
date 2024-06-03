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
    id: 1,
    name: "75Way technologies"
  }])
  p "Created #{Company.count} company"  
end

# Create roles
if Role.count == 0
  Role.create!([{
    id: 1,
    name: "ADMIN"
  },
  {
    id: 2,
    name: "STAFF"
  }])
  p "Created #{Role.count} roles"  
end

# 
if Integration.count == 0
  Integration.create!([
    {
      id: 1,
      name: "Microsoft Office 365",
      description: "Collaboration and cloud-based services owned by Microsoft",
      logo: "outlook.svg"
    },
    {
      id: 2,
      name: "AWS",
      description: "Provides on-demand cloud computing platforms and APIs.",
      logo: "aws.svg"
    },
    {
      id: 3,
      name: "Azure",
      description: "Provides on-demand cloud platforms and APIs.",
      logo: "azure.svg"
    },
    {
      id: 4,
      name: "Google Workspace",
      description: "Free collaboration and productivity apps for businesses of all sizes.",
      logo: "google.svg"
    },
    {
      id: 5,
      name: "Quickbooks",
      description: "Designed to help you manage your business finances with ease.",
      logo: "quickbooks.svg",
    },
    {
      id: 6,
      name: "Dropbox",
      description: "Provides cloud storage.",
      logo: "dropbox.svg"
    },
    {
      id: 7,
      name: "Google Cloud",
      description: "Provides infrastructure, data analytics, machine learning, and developer tools.",
      logo: "google-cloud.svg"
    },
    {
      id: 8,
      name: "Box",
      description: "Provides secure storage, collaboration tools, and workflow automation.",
      logo: "box.svg"
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