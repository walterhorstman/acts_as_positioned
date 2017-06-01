require('active_record')
require('minitest')
require('minitest/autorun')
require_relative('../lib/acts_as_positioned')

# Test by running: ruby test/acts_as_positioned_test.rb
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: File.dirname(__FILE__) + '/test.sqlite3')

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
    t.integer(:ordering)
  end
end

class BasicPost < ActiveRecord::Base
  self.table_name = 'posts'
  acts_as_positioned
end

# Basic tests.
class BasicTests < Minitest::Test
  def setup
    BasicPost.delete_all
    @post1 = BasicPost.create(text: '1st post', position: 0)
    @post2 = BasicPost.create(text: '2nd post', position: 1)
    @post3 = BasicPost.create(text: '3rd post', position: 2)
  end

  def test_insert_record
    post4 = BasicPost.create(text: '4th post', position: 1)
    assert_equal(post4.position, 1)
    assert_equal(@post1.reload.position, 0)
    assert_equal(@post2.reload.position, 2)
    assert_equal(@post3.reload.position, 3)
  end

  def test_delete_record
    @post2.destroy
    assert_equal(@post1.reload.position, 0)
    assert_equal(@post3.reload.position, 1)
  end

  def test_move_record_downwards
    @post1.update(position: 1)
    assert_equal(@post1.reload.position, 1)
    assert_equal(@post2.reload.position, 0)
    assert_equal(@post3.reload.position, 2)
  end

  def test_move_record_upwards
    @post3.update(position: 0)
    assert_equal(@post1.reload.position, 1)
    assert_equal(@post2.reload.position, 2)
    assert_equal(@post3.reload.position, 0)
  end

  def test_move_record_downwards_and_upwards
    @post1.update(position: 1)
    @post1.update(position: 0)
    assert_equal(@post1.reload.position, 0)
    assert_equal(@post2.reload.position, 1)
    assert_equal(@post3.reload.position, 2)
  end

  def test_insert_record_without_position_should_do_nothing
    post4 = BasicPost.create(text: '4th post')
    assert_nil(post4.position)
    assert_equal(@post1.reload.position, 0)
    assert_equal(@post2.reload.position, 1)
    assert_equal(@post3.reload.position, 2)
  end

  def test_clear_position
    @post1.update(position: nil)
    assert_equal(@post2.reload.position, 0)
    assert_equal(@post3.reload.position, 1)
  end

  def test_fill_position
    post4 = BasicPost.create(text: '4th post')
    assert_nil(post4.position)
    assert_equal(@post1.reload.position, 0)
    assert_equal(@post2.reload.position, 1)
    assert_equal(@post3.reload.position, 2)

    post4.update(position: 1)
    assert_equal(post4.position, 1)
    assert_equal(@post1.reload.position, 0)
    assert_equal(@post2.reload.position, 2)
    assert_equal(@post3.reload.position, 3)
  end

  def test_update_record_without_position_should_do_nothing
    post4 = BasicPost.create(text: 'Initial text', position: 0)
    assert_equal(post4.reload.position, 0)
    post4.update(text: 'Changed text')
    assert_equal(post4.reload.position, 0)
  end

  # First record that gets created, must have position 0.
  def test_validation
    post4 = BasicPost.new(text: 'Post', position: 4)
    assert_equal(post4.valid?, false)
  end
end

class ScopedPost < ActiveRecord::Base
  self.table_name = 'posts'
  acts_as_positioned(scope: :author_id)
end

# Scoped model tests.
class ScopedTests < Minitest::Test
  def setup
    ScopedPost.delete_all
    @post1 = ScopedPost.create(text: '1st post', position: 0)
    @post2 = ScopedPost.create(text: '1nd post for author 1', position: 0, author_id: 1)
    @post3 = ScopedPost.create(text: '2nd post for author 1', position: 1, author_id: 1)
  end

  def test_insert_record_with_scope_column
    post4 = ScopedPost.create(text: '3th post for author 1', position: 1, author_id: 1)
    assert_equal(post4.position, 1)
    assert_equal(@post1.reload.position, 0)
    assert_equal(@post2.reload.position, 0)
    assert_equal(@post3.reload.position, 2)
  end

  def test_reposition_when_author_changes
    @post2.update(author_id: nil)
    assert_equal(@post2.position, 0)
    assert_equal(@post1.reload.position, 1)
    assert_equal(@post3.reload.position, 0)
  end
end

# Animal base class to test single table inheritance.
class Animal < ActiveRecord::Base
  acts_as_positioned(column: :ordering)
end

# Cat sub class to test single table inheritance.
class Cat < Animal
end

# Dog sub class to test single table inheritance.
class Dog < Animal
end

class SingleTableInheritanceTests < Minitest::Test
  def test_single_table_inheritance
    cat = Cat.create(ordering: 0)
    dog = Dog.create(ordering: 0)
    assert_equal(dog.ordering, 0)
    assert_equal(cat.reload.ordering, 1)
  end
end
