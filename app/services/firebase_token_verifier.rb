require "base64"
require "json"
require "net/http"
require "openssl"
require "uri"

class FirebaseTokenVerifier
  CERTS_URL = "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com"
  ALGORITHM = "RS256"

  class VerificationError < StandardError; end

  def initialize(project_id: ENV["FIREBASE_PROJECT_ID"])
    @project_id = project_id.presence
  end

  def verify(id_token)
    raise VerificationError, "Firebase project is not configured" if @project_id.blank?
    raise VerificationError, "Missing Firebase ID token" if id_token.blank?

    encoded_header, encoded_payload, encoded_signature = id_token.split(".", 3)
    raise VerificationError, "Malformed Firebase ID token" unless encoded_header && encoded_payload && encoded_signature

    header = decode_json(encoded_header)
    payload = decode_json(encoded_payload)

    validate_header!(header)
    validate_claims!(payload)
    validate_signature!(encoded_header, encoded_payload, encoded_signature, header.fetch("kid"))

    payload
  rescue JSON::ParserError, ArgumentError, KeyError
    raise VerificationError, "Invalid Firebase ID token"
  end

  private

  def decode_json(segment)
    JSON.parse(Base64.urlsafe_decode64(pad_base64(segment)))
  end

  def pad_base64(segment)
    segment + ("=" * ((4 - segment.length % 4) % 4))
  end

  def validate_header!(header)
    raise VerificationError, "Unexpected Firebase token algorithm" unless header["alg"] == ALGORITHM
    raise VerificationError, "Firebase token key id is missing" if header["kid"].blank?
  end

  def validate_claims!(payload)
    issuer = "https://securetoken.google.com/#{@project_id}"
    now = Time.current.to_i

    raise VerificationError, "Firebase token has wrong issuer" unless payload["iss"] == issuer
    raise VerificationError, "Firebase token has wrong audience" unless payload["aud"] == @project_id
    raise VerificationError, "Firebase token subject is missing" if payload["sub"].blank?
    raise VerificationError, "Firebase token subject is invalid" if payload["sub"].length > 128
    raise VerificationError, "Firebase token is expired" unless payload["exp"].to_i > now
    raise VerificationError, "Firebase token was issued in the future" unless payload["iat"].to_i <= now
    raise VerificationError, "Firebase token email is unverified" unless payload["email_verified"] == true
  end

  def validate_signature!(encoded_header, encoded_payload, encoded_signature, kid)
    certificate = certificates.fetch(kid) { raise VerificationError, "Firebase token key id is unknown" }
    public_key = OpenSSL::X509::Certificate.new(certificate).public_key
    signed_data = "#{encoded_header}.#{encoded_payload}"
    signature = Base64.urlsafe_decode64(pad_base64(encoded_signature))

    unless public_key.verify(OpenSSL::Digest::SHA256.new, signature, signed_data)
      raise VerificationError, "Firebase token signature is invalid"
    end
  end

  def certificates
    Rails.cache.fetch("firebase_public_certificates", expires_in: 1.hour) do
      response = Net::HTTP.get_response(URI(CERTS_URL))
      raise VerificationError, "Could not load Firebase public certificates" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    end
  end
end
