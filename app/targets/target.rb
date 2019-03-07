# frozen_string_literal: true

# Helper class for targets (data access classes for Square business objects).
# It defines the target error types, the target type to class mapping, and
# a series of helper methods for working with targets.
#
# For more information on targets:
# https://docs.google.com/document/d/1Yi7aT5nCT2crDaNfFa96gn_rI2AOU7i33Ue1e65uyiI
module Target
    extend ModuleHelper

    Error = Class.new(StandardError)
    InvalidRequestError = Class.new(Target::Error)
    NotFoundError = Class.new(Target::Error)
    ForbiddenError = Class.new(Target::Error)

    # Mapping of target types to target classes. Targets without implementations
    # are unset and are considered TODO targets. These TODO targets are only used
    # in controller level permissioning with TargetPermission and must be declared
    # in registry_groups_per_target.yml.
    CLASS_FROM_TYPE = {
      ACCOUNT_ADJUSTMENT:              'AccountAdjustment',
      ACTIVATION_ATTEMPT:              'ActivationAttempt',
      ADDRESS:                         'Address',
      APPOINTMENT:                     nil,
      BADACTORS_SCREEN_RESULT:         'Badactors::ScreenResultResponse',
      BANK_ACCOUNT:                    'SqWeb::BankAccount',
      BANK_BRANCH:                     nil,
      BANK_SETTLEMENT:                 'BankSettlement',
      BAZAAR_EVENT:                    nil,
      BAZAAR_ORDER:                    nil,
      BILL:                            nil,
      BIN:                             nil,
      BUSINESS_BANKING:                'BusinessBanking::BizbankAccount',
      BUYER:                           nil,
      CAPITAL_AFC_OFFER_FLOW:          'Capital::AfcOfferFlow',
      CAPITAL_AGGREGATED_OFFER:        nil,
      CAPITAL_AGGREGATED_PLAN:         'Capital::AggregatedPlan',
      CAPITAL_APPLICATION_INFORMATION: nil,
      CAPITAL_BADACTORS_ENTITY:        nil,
      CAPITAL_BUSINESS_APPLICATION:    'Capital::BusinessApplication',
      CAPITAL_CONSUMER_APPLICATION:    'CapitalConsumer::ConsumerApplication',
      CAPITAL_CONSUMER_MARKETING:      nil,
      CAPITAL_CUSTOMER:                'CapitalCustomer',
      CAPITAL_LEGAL_ENTITY:            'Capital::LegalEntity',
      CAPITAL_PLAN:                    'Capital::Plan',
      CAPITAL_SHOP_PLAN:               'CapitalShop::Plan',
      CASE:                            'Kase',
      CASE_QUEUE:                      'KaseQueue',
      CASE_QUEUE_DETAIL:               'KaseQueueDetail',
      CASE_TYPE:                       'CaseType',
      CASH_BANKLIN_BALANCE:            nil,
      CASH_BANKLIN_TRANSACTION:        'SqCash::CashBanklinTransaction',
      CASH_BTC_TRANSFER:               nil,
      CASH_CARD_CUSTOMIZATION:         'SqCash::CardCustomization',
      CASH_CHARGEBACK:                 'CashChargeback',
      CASH_CUSTOMER:                   'FranklinCustomer',
      CASH_CUSTOMER_FILE:              nil,
      CASH_INSTRUMENT:                 nil,
      CASH_PAYMENT:                    'SqCash::Payment',
      CASH_PAYMENT_CARD:               nil,
      CASH_PLATFORM_CLIENT:            nil,
      CASH_TRANSFER:                   nil,
      CAVIAR_MERCHANT:                 nil,
      CLINTON_INVOICE:                 nil,
      CLINTON_PAYMENT_ATTEMPT:         nil,
      CONVERSATION:                    nil,
      DISPUTED_PAYMENT:                nil,
      EMAIL_ADDRESS:                   'EmailAddress',
      EMAIL_TEMPLATE:                  nil,
      ESPERANTO_PAYMENT:               nil,
      FLIPPER_DEVICE:                  'FlipperDevice',
      FREE_PROCESSING_ADJUSTMENT:      nil,
      GIFT_CARD:                       nil,
      GIFT_CARD_EVENT:                 nil,
      HARDWARE_ORDER:                  'HardwareOrder',
      INSTANT_DEPOSIT_CARD:            nil,
      INSTRUMENT:                      'Instrument',
      IRF_FORM:                        nil,
      LEDGER_ENTRY:                    'LedgerEntry',
      LEGAL_ENTITY_STRUCTURE:          'LegalEntityStructure',
      LEGIT_SCRIPT_RESPONSE:           'Badactors::LegitScriptResponse',
      MANUAL_APPROVAL_ACCESS:          'ManualApprovalAccess',
      MAXMIND_SCORE:                   nil,
      MONEY_TRANSFER:                  nil,
      MULTIPASS_CREDENTIAL:            nil,
      MULTIPASS_TWO_FACTOR:            nil,
      PAYMENT_CARD:                    nil,
      PAYMENT_LIMITS:                  'PaymentLimits',
      PAYMENT_RECEIPT:                 nil,
      PAYROLL:                         nil,
      PERSON:                          'Person',
      PLATFORM_ACCOUNT:                'PlatformAccount',
      POSTAL_CODE_GEOCODE:             nil,
      REDEMPTION_CODE:                 nil,
      REGISTER_CHARGEBACK:             'RegisterChargeback',
      REGISTER_DEVICE:                 nil,
      REGISTER_EMPLOYMENT:             'Mds::Employment',
      REGISTER_MERCHANT:               'Mds::Merchant',
      REGISTER_PAYMENT:                'SpotPayment',
      REGISTER_TAXMAN:                 nil,
      REGISTER_UNIT:                   'Mds::Unit',
      ROLODEX_CONTACT:                 nil,
      ROLODEX_CONTACT_CHANGED_EVENT:   nil,
      ROWO:                            'Rowo',
      SANTA_REGISTER_STATE:            nil,
      STORE_FRONT:                     nil,
      TAGGED_ENTITY:                   nil,
      TARKIN_HARDWARE:                 nil,
      TARKIN_TAMPER_EVENT:             nil,
      UHURA_CASE:                      nil,
      UHURA_UNIT:                      nil,
      US_BANK:                         'SqWeb::UsBank',
      WEB_PRESENCE:                    'WebPresence',
      # Please keep in alphabetical order
    }.with_indifferent_access
    private_constant :CLASS_FROM_TYPE

    # Define target type constants (i.e. Target::REGISTER_UNIT).
    # Also defines all type constants in an array with Target::ALL.
    def_constants(CLASS_FROM_TYPE.keys)

    # CLASS_FROM_TYPE classes must be initially defined as strings to avoid
    # circular dependency issues with their constants. Constantize them
    # back to classes here and freeze the mappings.
    begin
      CLASS_FROM_TYPE.keys.each do |key|
        value = CLASS_FROM_TYPE[key]
        CLASS_FROM_TYPE[key] = value.constantize if value.present?
      end

      CLASS_FROM_TYPE.freeze
    end

    # After constantizing CLASS_FROM_TYPE values, invert to have a mapping from
    # classes back to their type string constant
    TYPE_FROM_CLASS = CLASS_FROM_TYPE.invert.freeze
    private_constant :TYPE_FROM_CLASS

    # Returns true if current admin has the required permission to access to the
    # given target type for the given scope. Otherwise, returns false.
    def self.check_permission(
      target_type:,
      capability:,
      scope: TargetBase::Scope::DEFAULT,
      admin: Current.admin
    )
      access_config = TargetPermission.access_configuration_for_target_and_cap(
        target_type,
        capability,
        scope: scope,
      )

      # Currently only full access can be checked against a target type's
      # access types. Other access types require an instance of the target.
      full_access_groups = access_config[:full_access]
      admin.registry_group_names.include?(full_access_groups)
    end

    # Returns true if current admin has the required permission to access to the
    # given target type for the given scope. Otherwise, raises.
    def self.check_permission!(target_type:, capability:, scope: TargetBase::Scope::DEFAULT)
      unless check_permission(target_type: target_type, capability: capability, scope: scope)
        TargetPermission._handle_forbidden_error(target_type, capability, [scope])
      end

      true
    end

    # Target#build(type:, token: nil) returns a lazily loaded Target class. Similar
    # to #lookup except that it does not call `TargetBase#_fetch_target_data`.
    # NB: legacy target-like objects are not lazily loaded.
    def self.build(type:, token:)
      klass = class_from_type(type)
      if klass.present? && klass < TargetBase
        klass.new(token: token)
      else
        raise InvalidRequestError, "Invalid target type #{type}"
      end
    end

    # Returns the target object if given a single token or an array of target
    # objects if given an array of tokens. Raises a Target::NotFoundError if any
    # result is not found. Does not return duplicates.
    #
    # @param [String] type, the target type to look up
    # @param [String|Array<String>] token_or_tokens
    # @return A fetched object of the given type or an array of them if given
    #         multiple tokens.
    def self.lookup!(type:, token_or_tokens:)
      klass = class_from_type(type)
      if klass.present? && klass < TargetBase
        klass.lookup!(token_or_tokens)
      else
        raise InvalidRequestError, "Invalid target type #{type}"
      end
    end

    # Returns the target object if given a single token or an array of target
    # objects if given an array of tokens. If given a single token that does
    # not exist, returns nil. If given an array of tokens, will omit any
    # that do not exist. Does not return duplicates.
    #
    # @param [String] type, the target type to look up
    # @param [String|Array<String>] token_or_tokens
    # @return A fetched object of the given type or an array of them if given
    #         multiple tokens.
    def self.lookup(type:, token_or_tokens:)
      klass = class_from_type(type)
      if klass.present? && klass < TargetBase
        klass.lookup(token_or_tokens)
      else
        raise InvalidRequestError, "Invalid target type #{type}"
      end
    end

    # Given an object/class, return its target type or nil if invalid.
    def self.type_of(object_or_class)
      return nil if object_or_class.nil?

      if object_or_class.is_a?(String) && Target::ALL.include?(object_or_class)
        object_or_class
      elsif object_or_class.is_a?(Class)
        _type_from_class(object_or_class)
      else
        _type_from_class(object_or_class.class)
      end
    end

    # Check whether an object's target type is the provided target_type
    def self.type_is?(object, target_type)
      type_of(object) == target_type
    end

    def self.class_from_type(target_type)
      CLASS_FROM_TYPE[target_type]
    end

    private

    def self._type_from_class(klass)
      TYPE_FROM_CLASS[klass]
    end
    private_class_method :_type_from_class
  end

