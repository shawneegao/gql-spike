module TargetMethods
    attr_reader :token

    def self.included(klass)
      klass.extend(ClassMethods)
    end

    # Target instances are created with a token or underlying data object.
    #
    # Target subclasses should feel free to provide helper functions for
    # instantiation so that callers don't need to know details about the
    # underlying objects.
    def initialize(token: nil, target_data: nil, eager_load_data: nil)
      token = token.to_s

      if token.blank? && target_data.blank?
        raise Target::InvalidRequestError,
          "#{self.class} initializer: Token and target data are both unset"
      end
      
      if target_data.present?
        self.target_data = target_data
      else
        @token = token
      end

      @eager_load_data = eager_load_data
    end

    def reload
      instance_variables.each do |var|
        next if var == :@token # do not clear the token variable
        instance_variable_set(var, nil)
      end

      reloaded_data = self.class._safe_fetch_target_data(token)

      if reloaded_data.blank?
        @target_data = nil
        raise Target::NotFoundError,
          "Can not find #{self.class} object with token #{token}"
      end

      self.target_data = reloaded_data

      self
    end

    # Returns the associated target objects for this target.
    #
    # @param [Array<String>] filter_types If provided, return just the target
    #   objects of the given target types. Otherwise, return all target types.
    def associated_targets(filter_types = nil)
      filter_types = Array(filter_types || Target::ALL)
      filter_types &= Current.admin.readable_targets

      association_methods = filter_types.map do |filter_type|
        _association_method_for_type(filter_type)
      end.compact

      targets = association_methods.map do |method_or_method_and_args|
        begin
          Array(send(*method_or_method_and_args))
        rescue Target::ForbiddenError => error
          Sq::Common.exception_notifier.notify(
            "#{self.class.name}#associated_targets: Got forbidden error, skipping",
            caller: SentryHelper.callstack(15),
            target: self,
            association_method: method_or_method_and_args,
            filter_types: filter_types,
            reverse_associations: include_available_reverse_associations,
            message: error.message,
            level: 'warn',
          )

          nil
        end
      end.flatten.compact

      targets = Set.new(targets)

      # Don't include itself
      (targets - [self]).sort
    end

    def inspect
      if is_fetched?
        inspect_fetched
      else
        inspect_not_fetched
      end
    end

    def ==(other_object)
      other_object.try(:token) == token && other_object.is_a?(self.class)
    end
    alias :eql? :==

    def hash
      token.hash
    end

    def <=>(other_object)
      token <=> other_object.try(:token)
    end

    def target_data
      @target_data ||= reload.target_data
    end

    def check_permission!(capability)
      unless check_permission(capability)
        TargetPermission._handle_forbidden_error(Target.type_of(self), capability, target_scopes)
      end

      true
    end

    def check_permission(capability)
      !access_type(capability).blocked?
    end

    # Returns a TargetAccessType constant
    def access_type(capability)
      @access_type ||= {}
      @access_type[Current.admin.uid] ||= {}

      @access_type[Current.admin.uid][capability] ||= begin
        access_types = target_scopes.map do |scope|
          TargetAccessType.preferred_access_type_for_permission(admin: Current.admin, target: self, capability: capability, scope: scope)
        end

        # It's possible to have a different access type per scope if this target
        # has multiple scopes. Return the "least good" access type when this occurs
        # as determined by access type sort order. If any types are BLOCKED, BLOCKED
        # is always returned.
        access_types.sort_by do |type|
          TargetAccessType::SORT_ORDER.index(type)
        end.first
      end
    end

    private

    def target_data=(input_target_data)
      @target_data = input_target_data
      @token = _token
      # check_permission!(TargetCapability::READ)
      # EventstreamHelper.log_target_load(self)
    end

    def _association_method_for_type(type)
      registered_associations =
        self.class.instance_variable_get(:@_registered_associations)
      if registered_associations.blank?
        raise Target::TargetError,
          'Targets must specify either associated_targets or `has_no_associated_targets`'
      end

      registered_associations[type]
    end

    # Returns the set of all target types with which this target may associate.
    def associated_target_types
      self.class.instance_variable_get(:@_registered_associations).keys - [:none]
    end

    def get_eager_load_value(eager_load_key)
      @eager_load_data&.fetch(eager_load_key, nil) || (yield if block_given?)
    end

    def is_fetched?
      @target_data.present?
    end

    def valid_token?
      self.class.valid_token?(token)
    end

    def valid_target_data_class?
      self.class.valid_target_data_class?(target_data)
    end

    module ClassMethods
      # Returns true on success, or false on failure.
      def check_permission(capability, scope: TargetBase::Scope::DEFAULT)
        Target.check_permission(
          target_type: Target.type_of(self),
          capability: capability,
          scope: scope,
        )
      end

      # Returns nothing on success, or raises a Target::Forbidden error on failure.
      def check_permission!(capability, scope: TargetBase::Scope::DEFAULT)
        Target.check_permission!(
          target_type: Target.type_of(self),
          capability: capability,
          scope: scope,
        )
      end

      def associated_target(target_type, association_method)
        @_registered_associations ||= {}
        if @_registered_associations[:none]
          raise Target::TargetError,
            'Targets must not specify both associated_targets and `has_no_associated_targets`'
        end
        @_registered_associations[target_type] = association_method
      end

      def has_no_associated_targets
        if @_registered_associations.present?
          raise Target::TargetError,
            'Targets must not specify both associated_targets and `has_no_associated_targets`'
        end
        @_registered_associations = { none: true }
      end

      def polymorphic_association(method_name, types: Target::ALL)
        @_registered_associations ||= {}
        if @_registered_associations[:none]
          raise Target::TargetError,
            'Targets must not specify both associated_targets and `has_no_associated_targets`'
        end
        types.each do |target_type|
          @_registered_associations[target_type] = [method_name, target_type]
        end
      end
    end
  end

