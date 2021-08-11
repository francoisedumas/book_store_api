module Api
  module V1
    class BooksController < ApplicationController
      def index
        books = Book.all

        render json: books
      end

      def create
        author = Author.create!(author_params)
        book = Book.new(book_params)
        book.author = author

        if book.save
          render json: books
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
    end
  end
end