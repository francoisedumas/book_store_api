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
### Adding tests 😇

Go to your Gemfil and add below gem
```
group :development, :test do
  #...
  gem 'rspec-rails'
  gem 'factory_bot_rails'
end

group :test do
  gem 'database_cleaner-active_record'
end
```
In the terminal
```
bundle
rails generate rspec:install
```

```ruby
# in the rails_helper.rb uncomment below line
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }
# turn below line to false
config.use_transactional_fixtures = false
```

#### DB cleaner
Create a spec/support folder and add a database_cleaner_spec.rb file
```ruby
RSpec.configure do |config|

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, :js => true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

end
```
#### Creating factories
Create a spec/factories folder and add a book.rb and author.rb file
```ruby
# book.rb
FactoryBot.define do
  factory :book do
  end
end
# author.rb
FactoryBot.define do
  factory :author do
  end
end
```
#### the test itself
Create a spec/requests folder and add a book_spec.rb file
```ruby
require 'rails_helper'

describe 'Books API', type: :request do
  let(:first_author) { FactoryBot.create(:author, first_name: 'George', last_name: 'Orwell', age: 50)}
  let(:second_author) { FactoryBot.create(:author, first_name: 'H.G', last_name: 'Wells', age: 70)}

  describe 'GET /books' do
    before do
      FactoryBot.create(:book, title: '1984', author: first_author)
      FactoryBot.create(:book, title: 'The Time Machine', author: second_author)
    end

    it 'returns all books' do
      get '/api/v1/books'

      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body).size).to eq(2)
      expect(JSON.parse(response.body)).to eq(
        [
          {
          'id' => 1,
          'title' => '1984',
          'author_name' => 'George Orwell',
          'author_age' => 50
          },
          {
          'id' => 2,
          'title' => 'The Time Machine',
          'author_name' => 'H.G Wells',
          'author_age' => 70
          }
        ]
      )
    end
  end

  describe 'POST /books' do
    it 'create a new book' do
      expect {
        post '/api/v1/books', params: {
          book: { title: 'The Martian' },
          author: { first_name: 'Andy', last_name: 'Weir', age: '48'}
        }
      }.to change { Book.count }.from(0).to(1)

      expect(response).to have_http_status(:created)
      expect(Author.count).to eq(1)
      expect(JSON.parse(response.body)).to eq(
        {
          'id' => 1,
          'title' => 'The Martian',
          'author_name' => 'Andy Weir',
          'author_age' => 48
        }
      )
    end
  end

  describe 'DELETE /books/:id' do
    let!(:book) { FactoryBot.create(:book, title: '1984', author: first_author) }

    it 'deletes a book' do
      expect {
        delete "/api/v1/books/#{book.id}"
      }.to change { Book.count }.from(1).to(0)

      expect(response).to have_http_status(:no_content)
    end
  end
end
```
#### Drying test
Testing API we often use `JSON.parse(response.body)` to dry it up create a request_helper.rb file in spec folder
```ruby
module RequestHelper
  def response_body
    JSON.parse(response.body)
  end
end
```
In the spec_helper.rb file
```ruby
require 'request_helper'
# ...
# at the bottom in the config area before the last end add
config.include RequestHelper, type: :request
```
Now in every Rspec file with `type: :request` you can replace `JSON.parse(response.body)` by `response_body` and you don't need to use `require 'request_helper'` at the top of the file

### Pagination
To avoid sending to much information through the API we can use pagination to limit the size of info sent.
In the books_controller.rb
```ruby
# add the constant
MAX_PAGINATION_LIMIT = 100
# in the index function use below code instead
books = Book.limit(limit).offset(params[:offset])
render json: BooksRepresenter.new(books).as_json
# in the private section add the next function
def limit
  [
    params.fetch(:limit, MAX_PAGINATION_LIMIT).to_i,
    MAX_PAGINATION_LIMIT
  ].min
end
```

#### Request test
Add the next 2 tests to the 'GET /books' test
```ruby
it 'returns a subset of books based on limit' do
      get '/api/v1/books', params: { limit: 1 }

      expect(response).to have_http_status(:success)
      expect(response_body.size).to eq(1)
      expect(response_body).to eq(
        [
          {
          'id' => 1,
          'title' => '1984',
          'author_name' => 'George Orwell',
          'author_age' => 50
          }
        ]
      )
    end

    it 'returns a subset of books based on limit and offset' do
      get '/api/v1/books', params: { limit: 1, offset: 1 }

      expect(response).to have_http_status(:success)
      expect(response_body.size).to eq(1)
      expect(response_body).to eq(
        [
          {
          'id' => 2,
          'title' => 'The Time Machine',
          'author_name' => 'H.G Wells',
          'author_age' => 70
          }
        ]
      )
    end
```

#### Controllers tests
Create a spec/controllers folder and add a books_controller_spec.rb file
```ruby
require 'rails_helper'

RSpec.describe Api::V1::BooksController, type: :controller do
  it 'has a max limit of 100' do
    # explanation https://youtu.be/SQhj5gBNTB0 about 7:40
    expect(Book).to receive(:limit).with(100).and_call_original

    get :index, params: { limit: 999 }
  end
end
```