# frozen_string_literal: true
module API
  module V1
    class TokensController < API::V1::ApplicationController
      def create
        %w(email password).each do |param|
          next unless params[param].blank?
          render_error!(
            :unprocessable_entity,
            error_type: "missing_#{param}",
            error_message: "The '#{param}' parameter is required for authentication."
          )
        end

        user = User.find_for_authentication(email: params[:email])

        unless user && user.valid_password?(params[:password])
          render_error!(
            :unprocessable_entity,
            error_type: :invalid_credentials,
            error_message: 'The credentials you have provided are not valid.'
          )
        end

        unless user.active_for_authentication?
          render_error!(
            :unauthorized,
            error_type: user.inactive_message,
            error_message: t(
              "devise.failure.#{user.inactive_message}",
              default: 'You cannot authenticate at this moment.'
            )
          )
        end

        token = Knock::AuthToken.new payload: { sub: user.id }
        render status: :created, json: { token: token.token }
      end
    end
  end
end