class SignupsController < ApplicationController
  def new
    redirect_to(root_path) and return if logged_in?

    @user = User.new
  end

  def create
    unless params[:invite_code].to_s == Donburi::Exercise.invite_code
      @user = User.new(signup_params.except(:password))
      flash.now[:alert] = "招待コードが正しくありません。"
      return render :new, status: :unprocessable_entity
    end

    @user = nil
    Organization.transaction do
      org = Organization.create!(name: params[:organization_name].to_s.strip)
      @user = org.users.create!(signup_params)
    end

    start_session_for(@user)
    redirect_to root_path, notice: "アカウントを作成しました。"
  rescue ActiveRecord::RecordInvalid => e
    @user ||= User.new(signup_params.except(:password))
    flash.now[:alert] = e.record.errors.full_messages.to_sentence
    render :new, status: :unprocessable_entity
  end

  private

  def signup_params
    params.permit(:name, :email, :password)
  end
end
