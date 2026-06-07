class SessionsController < ApplicationController
  layout false

  def create
    if params[:id_token].present?
      create_from_firebase_token
    else
      create_from_password
    end
  end

  def omniauth
    auth = request.env["omniauth.auth"]
    user = User.from_omniauth(auth)

    unless user
      redirect_to login_path, alert: "Use your Northwestern Google account to log in."
      return
    end

    start_session_for(user)

    if user.previously_new_record?
      session[:requires_terms_acceptance] = true
      redirect_to onboarding_terms_path
    else
      redirect_to profile_path, notice: "Logged in with Google."
    end
  rescue ActiveRecord::RecordInvalid => error
    alert =
      if error.record.errors[:base].include?(ProfanityFilter::ERROR_MESSAGE)
        ProfanityFilter::ERROR_MESSAGE
      else
        "Could not log in with Google."
      end

    redirect_to login_path, alert: alert
  end

  def omniauth_failure
    redirect_to login_path, alert: "Google login was not completed."
  end

  def google_oauth_unconfigured
    redirect_to login_path, alert: "Google sign-in is unavailable until OAuth credentials are configured."
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Logged out."
  end

  private

  def create_from_firebase_token
    decoded_token = FirebaseTokenVerifier.new.verify(params.require(:id_token))
    email = decoded_token.fetch("email").to_s.downcase

    unless User.northwestern_email?(email)
      render json: { error: "Use your Northwestern email to log in." }, status: :forbidden
      return
    end

    user = User.find_or_initialize_by(email: email)
    new_user = user.new_record?
    user.assign_attributes(user_attributes(decoded_token, email))
    user.save!

    start_session_for(user)

    if new_user
      session[:requires_terms_acceptance] = true
    end

    render json: {
      user: {
        id: user.id,
        name: user.display_name,
        email: user.email
      },
      requires_terms_acceptance: new_user,
      terms_path: new_user ? onboarding_terms_path : nil
    }
  rescue ActionController::ParameterMissing
    render json: { error: "Missing Firebase ID token." }, status: :bad_request
  rescue FirebaseTokenVerifier::VerificationError
    render json: { error: "Could not verify Google login." }, status: :unauthorized
  rescue ActiveRecord::RecordInvalid => error
    render json: { error: error.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  end

  def create_from_password
    user = User.find_by(email: params[:email].to_s.strip.downcase)

    if user&.authenticate(params[:password].to_s)
      unless user.confirmed?
        flash.now[:alert] = "Use Google sign-in with your Northwestern account to verify before logging in."
        render "pages/login", status: :unprocessable_entity
        return
      end

      start_session_for(user)
      redirect_to profile_path, notice: "Logged in successfully."
    else
      flash.now[:alert] = "Invalid email or password."
      render "pages/login", status: :unprocessable_entity
    end
  end

  def start_session_for(user)
    reset_session
    session[:user_id] = user.id
  end

  def user_attributes(decoded_token, email)
    display_name = decoded_token["name"].presence || email.split("@").first
    name_parts = display_name.split

    {
      name: display_name,
      first_name: decoded_token["given_name"].presence || name_parts.first,
      last_name: decoded_token["family_name"].presence || name_parts.drop(1).join(" ").presence,
      profile_photo_url: decoded_token["picture"].presence,
      confirmed_at: Time.current,
      active: true
    }.compact
  end
end
