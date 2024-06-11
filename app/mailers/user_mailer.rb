class UserMailer < ApplicationMailer
  default from: 'noreply.75way@gmail.com'
  
  def welcome_email(user, url, isChangePassword = true)
    @user = user
    @url  = url
    @type = isChangePassword ? "change" : "set"
    @subject = isChangePassword ? "Change" : "Set" + ' your password'
    mail(to: @user.email, subject: @subject)
 end
end
