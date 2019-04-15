class TargetBase
  include TargetMethods
  extend TargetAnnotation
  extend ModuleHelper

  # REQUIRED
  # ==========================================================
  # Defines how to fetch data for the object given a id.
  def self._fetch_target_data(id)
    raise NotImplementedError
  end

  def self.lookup(id)
    target_data = _fetch_target_data(id)
    target_data.present? ? new(target_data: target_data) : nil
  end

  # OPTIONAL
  # ==========================================================
  # Class of the target data. Will be validated on initialization.
  # IRL will be overridden by the subclass i.e. Payments
  def self.target_data_class
    OpenStruct
  end

  def id 
    target_data.id 
  end 

  # Defaults to target type and id.
  def display_name
    "#{Target.type_of(self).titleize} #{id}"
  end

  def self.valid_id?(id)
    id.present?
  end
  
  # Returns the inspection of the type without fetched data.
  def inspect_not_fetched
    "#<#{self.class} id=\"#{id}\" is_fetched?=false>"
  end

  # Returns the inspection of the type with fetched data.
  def inspect_fetched
    "#<#{self.class} id=\"#{id}\" is_fetched?=true>"
  end
end
