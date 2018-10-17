# ActsAsPositioned (for ActiveRecord 3 or higher)

This gem allows you to have ordered models. It is like the old *acts_as_list*
gem, but very lightweight and with an optimized SQL syntax.

Suppose you want to order a Post model by position. You need to add a
`position` column to the table *posts* first.

    class CreatePost < ActiveRecord::Migration
      def change
        create_table(:posts) do |t|
          ...
          t.integer(:position, null: false)
        end
      end
    end

You can make the `position` column optional: only records with entered
positions will be ordered. In rare cases, you can also add extra order columns.

To add ordering to a model, do the following:

    class Post < ActiveRecord::Base
      acts_as_positioned
    end

You can also order within the scope of other columns, which is useful for
things like associations:

    class Detail < ActiveRecord::Base
      belongs_to(:post)
      acts_as_positioned(scope: :post_id)
    end

This means the order positions are unique within the scope of `post_id`.

# Examples

Check out the tests (in `test/lib/acts_as_positioned.rb`) to see more
examples.

Suppose you have these records (for all examples this is the starting point):

    id | position
    ---+---------
     1 |        0
     2 |        1
     3 |        2

## Insert a new record at position 1

The existing records with position greater than or equal to 1 will have their
position increased by 1 and the new record (with id 4) is inserted:

    Post.create(position: 1)

    id | position
    ---+---------
     1 |        0
     2 |        2 # moved down
     3 |        3 # moved down
     4 |        1 # inserted

## Delete a record at position 1

The existing records with position greater than or equal to 1 will have their
position decreased by 1 and the record (with id 2) is deleted:

    Post.find(2).destroy

    id | position
    ---+---------
     1 |        0
                  # deleted
     3 |        1 # moved up

## Move a record down from position 0 to position 1

The existing record with position equal to 1 will have its position decreased
by 1 and the record (with id 1) is moved down:

    Post.find(1).update(position: 1)

    id | position
    ---+---------
     1 |        1 # moved down
     2 |        0 # moved up
     3 |        2

## Move a record up from position 2 to position 0

The existing records with position greater than or equal to 0 and less than or
equal to 1 will have their position increased by 1 and the record (with id 3)
is moved up:

    Post.find(3).update(position: 0)

    id | position
    ---+---------
     1 |        1 # moved down
     2 |        2 # moved down
     3 |        0 # moved up

## Insert a new record at position 4

This would create a gap in the positions and is not allowed.

    Post.create(position: 4)

    id | position
    ---+---------
     1 |        0
     2 |        1
     3 |        2
     4 |        4 # invalid (thus not saved)

## Insert a new record with an empty position

This will not affect the other records.

    Post.create(position: nil)

    id | position
    ---+---------
     1 |        0
     2 |        1
     3 |        2
     4 |      nil # inserted, but without position

## Clear a record's position

Clearing a record's position, is like deleting its position.

    Post.find(1).update(position: nil)

    id | position
    ---+---------
     1 |      nil
     2 |        0 # moved up
     3 |        1 # moved up

# Copyright

&copy; 2017 Walter Horstman, [IT on Rails](http://itonrails.com)
