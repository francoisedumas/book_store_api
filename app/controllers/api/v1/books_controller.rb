module Api
  module V1
    class BooksController < ApplicationController
      # this is a rails method to access the token
      # https://api.rubyonrails.org/classes/ActionController/HttpAuthentication/Token.html
      include ActionController::HttpAuthentication::Token

      MAX_PAGINATION_LIMIT = 100

      before_action :authenticate_user, only: [:create, :destroy] # everyone can access the index

      def index
        # here the limit into bracket is a function define in the private section
        books = Book.limit(limit).offset(params[:offset])

        render json: BooksRepresenter.new(books).as_json
      end

      def create
        author = Author.create!(author_params)
        book = Book.new(book_params)
        book.author = author

        UpdateSkuJob.perform_later(book_params[:title])

        if book.save
          render json: BookRepresenter.new(book).as_json, status: :created
        else
          render json: book.errors, status: :unprocessable_entity
        end
      end

      def destroy
        Book.find(params[:id]).destroy!

        head :no_content
      end

      private

      def book_params
        params.require(:book).permit(:title)
      end

      def author_params
        params.require(:author).permit(:first_name, :last_name, :age)
      end

      def limit
        [
          params.fetch(:limit, MAX_PAGINATION_LIMIT).to_i,
          MAX_PAGINATION_LIMIT
        ].min
      end

      def authenticate_user
        # get the token with provided method
        token, _options = token_and_options(request)
        # decode the token with our service
        user_id = AuthenticationTokenService.decode(token)
        # raise user_id.inspect
        # check that user exist in our database
        User.find(user_id)
      rescue ActiveRecord::RecordNotFound
        render status: :unauthorized
      end
    end
  end
end
