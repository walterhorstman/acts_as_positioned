require('active_record')
require('minitest')
require('minitest/autorun')
require('acts_as_positioned')

# Test by running: ruby -Ilib test/lib/acts_as_positioned_test.rb
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: File.dirname(__FILE__) + '/../test.sqlite3')

# Create "posts" table.
ActiveRecord::Schema.define do
  create_table(:posts, force: true) do |t|
    t.string(:text, null: false)
    t.integer(:position)
    t.integer(:author_id)
  end
end

# Create "animals" table.
ActiveRecord::Schema.define do
  create_table(:animals, force: true) do |t|
    t.string(:type, null: false)
    t.string(:sound, null: false)
    t.integer(:ordering)
  end
end

class Post < ActiveRecord::Base
  acts_as_positioned
end

class PostWithScope < ActiveRecord::Base
  self.table_name = 'posts'
  acts_as_positioned(scope: :author_id)
end

class Animal < ActiveRecord::Base
  acts_as_positioned(column: :ordering)
end

class Cat < Animal
end

class Dog < Animal
end

class ActsAsPositionedTest < Minitest::Test
  def setup
    Post.delete_all
  end

  def test_insert_record
    post1 = Post.create(text: '1st post', position: 0)
    post2 = Post.create(text: '2nd post', position: 1)
    post3 = Post.create(text: '3rd post', position: 2)
    post4 = Post.create(text: '4th post', position: 1)
    assert_equal(post4.position, 1)
    assert_equal(post1.reload.position, 0)
    assert_equal(post2.reload.position, 2)
    assert_equal(post3.reload.position, 3)
  end

  def test_delete_record
    post1 = Post.create(text: '1st post', position: 0)
    post2 = Post.create(text: '2nd post', position: 1)
    post3 = Post.create(text: '3rd post', position: 2)
    post2.destroy
    assert_equal(post1.reload.position, 0)
    assert_equal(post3.reload.position, 1)
  end

  def test_move_record_downwards
    post1 = Post.create(text: '1st post', position: 0)
    post2 = Post.create(text: '2nd post', position: 1)
    post3 = Post.create(text: '3rd post', position: 2)
    post1.update(position: 1)
    assert_equal(post1.reload.position, 1)
    assert_equal(post2.reload.position, 0)
    assert_equal(post3.reload.position, 2)
  end

  def test_move_record_upwards
    post1 = Post.create(text: '1st post', position: 0)
    post2 = Post.create(text: '2nd post', position: 1)
    post3 = Post.create(text: '3rd post', position: 2)
    post3.update(position: 0)
    assert_equal(post1.reload.position, 1)
    assert_equal(post2.reload.position, 2)
    assert_equal(post3.reload.position, 0)
  end

  def test_move_record_downwards_and_upwards
    post1 = Post.create(text: '1st post', position: 0)
    post2 = Post.create(text: '2nd post', position: 1)
    post3 = Post.create(text: '3rd post', position: 2)
    post1.update(position: 1)
    post1.update(position: 0)
    assert_equal(post1.reload.position, 0)
    assert_equal(post2.reload.position, 1)
    assert_equal(post3.reload.position, 2)
  end

  def test_insert_record_without_position_should_do_nothing
    post1 = Post.create(text: '1st post', position: 0)
    post2 = Post.create(text: '2nd post', position: 1)
    post3 = Post.create(text: '3rd post', position: 2)
    post4 = Post.create(text: '4th post')
    assert_nil(post4.position)
    assert_equal(post1.reload.position, 0)
    assert_equal(post2.reload.position, 1)
    assert_equal(post3.reload.position, 2)
  end

  def test_clear_position
    post1 = Post.create(text: '1st post', position: 0)
    post2 = Post.create(text: '2nd post', position: 1)
    post3 = Post.create(text: '3rd post', position: 2)
    post1.update(position: nil)
    assert_equal(post2.reload.position, 0)
    assert_equal(post3.reload.position, 1)
  end

  def test_fill_position
    post1 = Post.create(text: '1st post', position: 0)
    post2 = Post.create(text: '2nd post', position: 1)
    post3 = Post.create(text: '3rd post', position: 2)
    post4 = Post.create(text: '4th post')
    assert_nil(post4.position)
    assert_equal(post1.reload.position, 0)
    assert_equal(post2.reload.position, 1)
    assert_equal(post3.reload.position, 2)

    post4.update(position: 1)
    assert_equal(post4.position, 1)
    assert_equal(post1.reload.position, 0)
    assert_equal(post2.reload.position, 2)
    assert_equal(post3.reload.position, 3)
  end

  def test_update_record_without_position_should_do_nothing
    post = Post.create(text: 'Initial text', position: 0)
    assert_equal(post.reload.position, 0)
    post.update(text: 'Changed text')
    assert_equal(post.reload.position, 0)
  end

  # First record that gets created, must have position 0.
  def test_validation
    post = Post.new(text: 'Post', position: 4)
    assert_equal(post.valid?, false)
  end

  def test_insert_record_with_scope_column
    post1 = PostWithScope.create(text: '1st post', position: 0)
    post2 = PostWithScope.create(text: '1nd post for author 1', position: 0, author_id: 1)
    post3 = PostWithScope.create(text: '2nd post for author 1', position: 1, author_id: 1)
    post4 = PostWithScope.create(text: '3th post for author 1', position: 1, author_id: 1)
    assert_equal(post4.position, 1)
    assert_equal(post1.reload.position, 0)
    assert_equal(post2.reload.position, 0)
    assert_equal(post3.reload.position, 2)
  end

  def test_reposition_when_author_changes
    post1 = PostWithScope.create(text: '1st post', position: 0)
    post2 = PostWithScope.create(text: '1nd post for author 1', position: 0, author_id: 1)
    post3 = PostWithScope.create(text: '2nd post for author 1', position: 1, author_id: 1)
    post2.update(author_id: nil)
    assert_equal(post2.position, 0)
    assert_equal(post1.reload.position, 1)
    assert_equal(post3.reload.position, 0)
  end

  def test_single_table_inheritance
    cat = Cat.create(sound: 'Miaow', ordering: 0)
    dog = Dog.create(sound: 'Bark', ordering: 0)
    assert_equal(dog.ordering, 0)
    assert_equal(cat.reload.ordering, 1)
  end
end
