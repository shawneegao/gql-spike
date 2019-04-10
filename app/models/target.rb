# Helper class for targets (data access classes for Square business objects).
# It defines the target type to class mapping, and
# helper methods for working with targets.

module Target
  extend ModuleHelper

  # Mapping of target constants to target classes.
  CLASS_FROM_SYM = {
    :PAYMENT => 'Payment',
    :MERCHANT => 'Merchant',
    :CARD => 'Card', 
  }.with_indifferent_access
  private_constant :CLASS_FROM_SYM

  # Define target type constants (i.e. :Payment)
  def_constants(CLASS_FROM_SYM.keys)

  def self.all_target_classes
    CLASS_FROM_SYM.values
  end

  def self.class_from_sym(target_sym)
    CLASS_FROM_SYM[target_sym]
  end

  begin
    CLASS_FROM_SYM.keys.each do |key|
      value = CLASS_FROM_SYM[key]
      CLASS_FROM_SYM[key] = value.constantize if value.present?
    end

    CLASS_FROM_SYM.freeze
  end
end

