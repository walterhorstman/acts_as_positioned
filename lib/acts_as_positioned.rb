# This module allow models to be positioned (order on a specific column). See the README file for more information.
module ActsAsPositioned
  def self.included(base)
    base.extend(ClassMethods)
  end

  # Class methods that will be added to the base class (the class mixing in this module).
  module ClassMethods
    def acts_as_positioned(options = {})
      column = options[:column] || :position
      scope_columns = Array.wrap(options[:scope])

      after_validation do
        acts_as_positioned_validation(column, scope_columns)
      end

      before_create do
        acts_as_positioned_create(column, scope_columns)
      end

      before_destroy do
        acts_as_positioned_destroy(column, scope_columns)
      end

      before_update do
        acts_as_positioned_update(column, scope_columns)
      end
    end
  end

  private

  def acts_as_positioned_create(column, scope_columns)
    scope = acts_as_positioned_scope(column, scope_columns)
    scope.where(scope.arel_table[column].gteq(send(column))).update_all("#{column} = #{column} + 1")
  end

  def acts_as_positioned_destroy(column, scope_columns)
    scope = acts_as_positioned_scope(column, scope_columns, true)
    scope.where(scope.arel_table[column].gt(send("#{column}_was"))).update_all("#{column} = #{column} - 1")
  end

  def acts_as_positioned_scope(column, scope_columns, use_old_values = false)
    scope_columns.reduce(self.class.base_class.where.not(column => nil)) do |scope, scope_column|
      scope.where(scope_column => use_old_values ? send("#{scope_column}_was") : send(scope_column))
    end
  end

  def acts_as_positioned_update(column, scope_columns)
    if scope_columns.any? { |scope_column| send("#{scope_column}_changed?") }
      acts_as_positioned_create(column, scope_columns)
      acts_as_positioned_destroy(column, scope_columns)

    elsif send(:"#{column}_changed?")
      old_value, new_value = send("#{column}_change")

      # If the new position becomes nil (and thus the old position wasn't), it should destroy a position.
      if new_value.nil?
        acts_as_positioned_destroy(column, scope_columns)

      # If the old position was nil (and thus the new position isn't), it should insert a position.
      elsif old_value.nil?
        acts_as_positioned_create(column, scope_columns)

      else
        from, to, sign = old_value < new_value ? [old_value + 1, new_value, '-'] : [new_value, old_value - 1, '+']

        acts_as_positioned_scope(column, scope_columns)
          .where(column => from.eql?(to) ? from : from..to)
          .update_all("#{column} = #{column} #{sign} 1")
      end
    end
  end

  def acts_as_positioned_validation(column, scope_columns)
    return if errors[column].any?
    return if !send(:"#{column}_changed?") && scope_columns.none? { |sc| send("#{sc}_changed?") }

    scope = acts_as_positioned_scope(column, scope_columns)
    scope = scope.where(scope.arel_table[scope.primary_key].not_eq(id)) unless new_record?
    options = { attributes: column, allow_nil: true, only_integer: true, greater_than_or_equal_to: 0,
                less_than_or_equal_to: (scope.maximum(column) || -1) + 1 }

    ActiveModel::Validations::NumericalityValidator.new(options).validate(self)
  end
end

ActiveSupport.on_load(:active_record) do
  include(ActsAsPositioned)
end
