# Query interface shared by targets
module TargetQueryable
  # Returns the target object if given a single id.
  def lookup(id, eager_load_options: [], raise_on_forbidden: true)
    target_data = _fetch_target_data(id)
    target_data.present? ? new(target_data: target_data) : nil
  end
end
