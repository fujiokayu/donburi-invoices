class SessionsController < ApplicationController
  def new
    redirect_to root_path if logged_in?
  end

  def create
    email = params[:email].to_s.strip.downcase
    user = User.find_by(email: email)

    if user&.authenticate(params[:password])
      start_session_for(user)
      AuthLog.record!(event: "login.success", email: email, user: user,
                      ip: client_ip, user_agent: request.user_agent)
      redirect_to root_path, notice: "ログインしました。"
    else
      AuthLog.record!(event: "login.failure", email: email,
                      ip: client_ip, user_agent: request.user_agent)
      flash.now[:alert] = "メールアドレスまたはパスワードが違います。"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    current_session&.destroy
    cookies.delete(:session_token)
    redirect_to login_path, notice: "ログアウトしました。"
  end
end
