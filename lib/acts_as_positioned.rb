# This module allow models to be positioned (order on a specific column). See the README file for more information.
module ActsAsPositioned
  def self.included(base)
    base.extend(ClassMethods)
  end

  # Class methods that will be added to the base class (the class mixing in this module).
  module ClassMethods
    def acts_as_positioned(options = {})
      column = (options[:column] || :position).to_s
      scope_columns = Array.wrap(options[:scope]).map(&:to_s)

      after_validation do
        aap_validate_position(column, scope_columns)
      end

      before_create do
        aap_insert_position(column, scope_columns)
      end

      before_destroy do
        aap_remove_position(column, scope_columns)
      end

      before_update do
        aap_update_position(column, scope_columns)
      end
    end
  end

  private

  def aap_execute_query(column, scope, downwards)
    quoted_column = scope.connection.quote_column_name(column)
    scope.update_all("#{quoted_column} = #{quoted_column} #{downwards ? '+' : '-'} 1")
  end

  def aap_insert_position(column, scope_columns)
    return if send(column).nil?

    scope = aap_scope(column, scope_columns, false)
    aap_execute_query(column, scope.where(scope.arel_table[column].gteq(send(column))), true)
  end

  def aap_remove_position(column, scope_columns)
    return if send("#{column}_was").nil?

    scope = aap_scope(column, scope_columns, true)
    aap_execute_query(column, scope.where(scope.arel_table[column].gt(send("#{column}_was"))), false)
  end

  def aap_scope(column, scope_columns, use_old_values)
    # When using the old values, make sure to overwrite the attribute values with the old values.
    attrs = use_old_values ? attributes.merge(changed_attributes) : attributes
    self.class.base_class.where(attrs.slice(*scope_columns)).where.not(column => nil)
  end

  def aap_switch_positions(column, scope_columns)
    old_value, new_value = changes[column]
    from = [old_value + 1, new_value].min
    to = [old_value - 1, new_value].max

    aap_execute_query(column, aap_scope(column, scope_columns, false).where(column => from.eql?(to) ? from : from..to),
                      old_value > new_value)
  end

  def aap_update_position(column, scope_columns)
    if (changes.keys & scope_columns).present?
      aap_insert_position(column, scope_columns)
      aap_remove_position(column, scope_columns)

    elsif changes.key?(column)
      # If the position was nil, it should insert a position.
      if changes[column][0].nil?
        aap_insert_position(column, scope_columns)

      # If the position becomes nil, it should remove a position.
      elsif changes[column][1].nil?
        aap_remove_position(column, scope_columns)

      else
        aap_switch_positions(column, scope_columns)
      end
    end
  end

  def aap_validate_position(column, scope_columns)
    return if send(column).nil? || errors[column].present? || (changes.keys & ([column] + scope_columns)).empty?

    scope = aap_scope(column, scope_columns, false)
    options = { attributes: column, allow_nil: true, greater_than_or_equal_to: 0, only_integer: true,
                less_than_or_equal_to: scope.where.not(scope.primary_key => id).count }
    ActiveModel::Validations::NumericalityValidator.new(options).validate(self)
  end
end

ActiveSupport.on_load(:active_record) do
  include(ActsAsPositioned)
end
