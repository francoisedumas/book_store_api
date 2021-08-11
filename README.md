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