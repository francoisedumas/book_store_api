require 'rails_helper'

# Here we will test a class method
describe AuthenticationTokenService do
  describe '.call' do # Here call is a method of the class AuthenticationTokenService
    it 'returns an authentication token' do

      # See the decode part of HMAC https://github.com/jwt/ruby-jwt

      token = described_class.call
      decoded_token = JWT.decode(
        token,
        described_class::HMAC_SECRET,
        true,
        { algorithm: described_class::ALGORITHM_TYPE }
      )

      expect(decoded_token).to eq(
        [
          {"test" => "blah"}, # payload
          {"alg"=>"HS256"} # header
        ]
      )
    end
  end
end
