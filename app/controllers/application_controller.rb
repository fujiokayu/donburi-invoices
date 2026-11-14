class ApplicationController < ActionController::Base
  helper_method :current_user, :current_organization, :logged_in?

  private

  def current_session
    return @current_session if defined?(@current_session)

    token = cookies.signed[:session_token]
    @current_session = token.present? ? Session.find_by(token: token) : nil
  end

  def current_user
    current_session&.user
  end

  def current_organization
    current_user&.organization
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    return if logged_in?

    redirect_to login_path, alert: "ログインしてください。"
  end

  def start_session_for(user)
    session = user.sessions.create!(ip: client_ip, user_agent: request.user_agent)
    cookies.signed[:session_token] = {
      value: session.token,
      httponly: true,
      same_site: :lax,
      secure: Rails.env.production?
    }
    session
  end

  def client_ip
    request.remote_ip
  end
end
