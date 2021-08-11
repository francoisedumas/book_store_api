# RoR API
## Introduction to API using Ruby on Rails

The target is to build a simple book store application using
 - RoR as an API back end
 - ...

<img width="1272" alt="Screenshot 2021-07-02 at 16 19 25" src="https://user-images.githubusercontent.com/33062224/124288579-9f841700-db51-11eb-9746-d943bf014b38.png">

## Starting with basic models and controllers

### Rails new

Let's start by creating a new Rails app with only api features
In the terminal
```
rails new book_store_api --api

cd book_store_api
git add . && git commit -m "Book store api"
gh repo create
git push origin master
```
### Generating the author and book model

```
rails g model Book title:string
rails g model Author first_name:string last_name:string age:integer
rails db:migrate
rails g migration add_author_to_books author:references
```
In this last migration file modify as below removing `null: false, foreign_key: true`
```ruby
class AddAuthorToBooks < ActiveRecord::Migration[6.1]
  def change
    add_reference :books, :author
  end
end
```
Then `rails db:migrate`

Now let's update the book model adding a validation and association
```ruby
  validates :title, presence: true, length: {minimum: 3}
  belongs_to :author
```

And similarly for the author model
```ruby
  has_many :books
```

### API: routes & controllers

Now we will create the structure of our app for the API.
Go to the file routes.rb and create the below routes
```ruby
namespace :api do
  namespace :v1 do
    resources :books, only: [:index, :create, :destroy]
  end
end
```
build the next folder structure in your app/controllers folder
```
/controllers
    /api
        /v1
```
In this folder create books_controller.rb

### Book controller

In your Book controller file add below controller
Comment: the module API / module V1 structure is key
```ruby
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
```

### Manual Seeds

Let's create some data go in the irb
`author = Author.create!(first_name: 'George', last_name: 'Orwell', age: 50)`
`Book.create!(title: '1984', author: author)`
`Book.create!(title: 'Animal Farm', author: author)`

### Representer

So far we push everything in our API let's shape it as we want it to be
Add a representers folder in your app/ folder
```
/app
    /representers
      books_representer.rb
      book_representer.rb
```
Add the below code for the books
```ruby
class BooksRepresenter
  def initialize(books)
    @books = books
  end

  def as_json
    books.map do |book|
      {
        id: book.id,
        title: book.title,
        author_name: author_name(book),
        author_age: book.author.age
      }
    end
  end

  private

  attr_reader :books

  def author_name(book)
    "#{book.author.first_name} #{book.author.last_name}"
  end
end
```

And below code for book
```ruby
class BookRepresenter
  def initialize(book)
    @book = book
  end

  def as_json
    {
      id: book.id,
      title: book.title,
      author_name: author_name(book),
      author_age: book.author.age
    }
  end

  private

  attr_reader :book

  def author_name(book)
    "#{book.author.first_name} #{book.author.last_name}"
  end
end
```

In the books controller replace as below
```ruby
# before
def index
  render json: Book.all
end

#after
def index
  books = Book.all

  render json: BooksRepresenter.new(books).as_json
end

# in the create function do the same update
if book.save
  render json: BookRepresenter.new(book).as_json, status: :created
else
```
