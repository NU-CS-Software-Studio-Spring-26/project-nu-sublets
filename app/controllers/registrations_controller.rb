class RegistrationsController < ApplicationController
  layout false

  def new
    redirect_to profile_path, notice: "You are already logged in." if user_signed_in?

    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    @user.active = true
    @user.require_password = true

    if @user.save
      reset_session
      session[:user_id] = @user.id
      redirect_to profile_path, notice: "Account created successfully."
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
