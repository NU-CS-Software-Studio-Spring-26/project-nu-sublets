class SessionsController < ApplicationController
  def create
    decoded_token = FirebaseTokenVerifier.new.verify(params.require(:id_token))
    email = decoded_token.fetch("email").to_s.downcase

    unless User.northwestern_email?(email)
      render json: { error: "Use your Northwestern email to log in." }, status: :forbidden
      return
    end

    user = User.find_or_initialize_by(email: email)
    user.assign_attributes(user_attributes(decoded_token, email))
    user.save!

    session[:user_id] = user.id

    render json: {
      user: {
        id: user.id,
        name: user.display_name,
        email: user.email
      }
    }
  rescue ActionController::ParameterMissing
    render json: { error: "Missing Firebase ID token." }, status: :bad_request
  rescue FirebaseTokenVerifier::VerificationError
    render json: { error: "Could not verify Google login." }, status: :unauthorized
  end

  def destroy
    reset_session
    redirect_to root_path
  end

  private

  def user_attributes(decoded_token, email)
    display_name = decoded_token["name"].presence || email.split("@").first
    name_parts = display_name.split

    {
      name: display_name,
      first_name: decoded_token["given_name"].presence || name_parts.first,
      last_name: decoded_token["family_name"].presence || name_parts.drop(1).join(" ").presence,
      active: true
    }
  end
end
