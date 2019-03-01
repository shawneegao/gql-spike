  # Target Classes must all inherit from this class
  # this class is broken into 3 sections:
  #
  # Required Methods: every subclass MUST overwrite these
  # =====
  # Optional Methods: a subclass can choose to overwrite these
  # =====
  # Association Methods: Every subclass must declare their association to other targets.
  # If a target has no associated targets, declare `has_no_associated_targets`
  #
  # For example, if a REGISTER_UNIT is associated to a REGISTER_MERCHANT
  # the Mds::Unit class must contain 2 things:
  # (1) Declare the association at the top of the class.
  #     ex: `associated_target TARGET::REGISTER_MERCHANT, merchant`
  #
  # (2) Define a method to retrieve the associated target object.
  #     ex: def merchant
  #           @merchant ||= Mds::Merchant.new(token: merchant_token)
  #         end
  class TargetBase
    include TargetMethods
    extend TargetQueryable
    extend TargetAnnotation
    extend ModuleHelper

    # Required Methods
    #
    # every subclass must overwrite these
    # ==========================================================

    # Defines how to fetch data for the object given a token. This function will
    # be used for reloading data and for lazy-loading of data. Returns an
    # instance of the target data class.
    #
    # Should return nil if the target object is not found.
    def self._fetch_target_data(_token)
      raise NotImplementedError
    end

    # Class of the target data. Will be validated on initialization.
    # Note: This is not required if using ProtoWrappable's `wraps_proto`
    def self.target_data_class
      raise NotImplementedError
    end

    # Optional Methods
    #
    # a subclass can choose to overwrite these or use existing behavior
    # ==========================================================

    # Override this if the target's identifier is not available in a
    # field named `token` in `target_data`
    def _token
      target_data.token
    end

    # Defines the way the target object represents itself in the UI
    # For example, merchant objects may want to use the Business name.
    #
    # Defaults to target type and token.
    def display_name
      "#{Target.type_of(self).titleize} #{token}"
    end

    # Subclasses can choose to override this. For example Sq Cash and Capital
    # customer token are both identifiable by a standard prefix (C_ and C-
    # respectively).
    def self.valid_token?(token)
      token.present?
    end

    # Defines how to fetch a batch of data for the object given a set of tokens.
    # Returns an array of the target data class.
    #
    # Should omit results in the return value that are not found.
    #
    # Override if a client batch lookup endpoint is available,
    # otherwise batch lookups will use multiple calls to the
    # _fetch_target_data client endpoint.
    def self._fetch_target_data_batch(tokens)
      tokens.map { |token| _safe_fetch_target_data(token) }.compact
    end

    # Override _query if the target can be fetched or queried by anything other
    # than `token`. Must return an enumerable PagedResult.
    # for nothing found, return an empty PagedResult: PagedResult([], nil).
    def self._query(**_params)
      raise NotImplementedError
    end

    # Defines how to pre-fetch certain data from a target data batch. This is
    # useful during batch lookups to avoid N+1 queries.
    #
    # Optional. Override to allow eager_load_options in batch lookups
    # when the resulting batch operation would be inefficient without this
    #
    # Returns a hash with each eager_load_option as keys.
    def self._fetch_eager_load_data(_target_data_batch, _eager_load_options)
      raise NotImplementedError
    end

    # Returns the inspection of the type without fetched data.
    #
    # Override if the string representation of the Target would
    # be more helpful if it contained more than just the type and token.
    def inspect_not_fetched
      "#<#{self.class} token=\"#{token}\" is_fetched?=false>"
    end

    # Returns the inspection of the type with fetched data.
    #
    # Override if the string representation of the Target would
    # be more helpful if it contained more than just the type and token.
    def inspect_fetched
      "#<#{self.class} token=\"#{token}\" is_fetched?=true>"
    end

    def as_json(_options = nil)
      {
        _target_type: Target.type_of(self),
        _target_token: self.token,
      }
    end
  end
