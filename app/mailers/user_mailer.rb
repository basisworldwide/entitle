class UserMailer < ApplicationMailer
  default from: 'noreply.75way@gmail.com'
  
  def welcome_email(user, url, isChangePassword = true)
    @user = user
    @url  = url
    @type = isChangePassword ? "change" : "set"
    @subject = isChangePassword ? "Change" : "Set" + ' your password'
    mail(to: @user.email, subject: @subject)
  end

  def workspace_invitation(name, secondary_email, email, password)
    @name = name
    @email = email
    @password = password
    @subject = "Workspace Invitation"
    mail(to: secondary_email, subject: @subject)
  end
end
