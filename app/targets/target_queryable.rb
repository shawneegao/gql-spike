# Query interface shared by targets
module TargetQueryable
  # Returns the target object if given a single token or an array of target
  # objects if given an array of tokens. If given a single token that does
  # not exist, returns nil. If given an array of tokens, will omit any
  # that do not exist. Does not return duplicates.
  #
  # @param [Array] eager_load_options Optional array specifying data to prefetch
  #   usually during batch looks to avoid N+1 queries.
  def lookup(token_or_tokens, eager_load_options: [], raise_on_forbidden: true)
    if token_or_tokens.is_a?(Array)
      tokens = token_or_tokens.uniq.compact
      target_data_batch = begin
        _safe_fetch_target_data_batch(tokens)
      rescue Target::ForbiddenError
        raise if raise_on_forbidden
        return []
      end

      # If any pre-load data is requested, fetch it with the batch
      eager_load_data = if eager_load_options.present?
        _safe_fetch_eager_load_data(target_data_batch, Array(eager_load_options))
      else
        {}
      end

      begin
        target_data_batch.map do |target_data|
          new(target_data: target_data, eager_load_data: eager_load_data)
        end
      rescue Target::ForbiddenError
        raise if raise_on_forbidden
        target_data_batch.map do |target_data|
          begin
            new(target_data: target_data, eager_load_data: eager_load_data)
          rescue Target::ForbiddenError
            nil
          end
        end.compact
      end
    else
      begin
        target_data = _safe_fetch_target_data(token_or_tokens)
        target_data.present? ? new(target_data: target_data) : nil
      rescue Target::ForbiddenError
        raise if raise_on_forbidden
        nil
      end
    end
  end

  # Returns the target object if given a single token or an array of target
  # objects if given an array of tokens. Raises if any result is not found.
  # Does not return duplicates.
  #
  # @param [Array] eager_load_options Optional array specifying data to prefetch
  #   usually during batch looks to avoid N+1 queries.
  def lookup!(token_or_tokens, eager_load_options: [])
    result = lookup(token_or_tokens, eager_load_options: eager_load_options)
    if token_or_tokens.is_a?(Array)
      token_or_tokens = token_or_tokens.uniq.compact
      if token_or_tokens.size != result.size
        missing_tokens = token_or_tokens - result.map(&:token)

        raise Target::NotFoundError,
          "Targets of type #{self} with tokens #{missing_tokens} not found"
      end
    elsif token_or_tokens.present? && result.blank?
      raise Target::NotFoundError,
        "Target of type #{self} with token #{token_or_tokens} not found"
    end

    result
  end

  # @returns PagedResult
  def query(eager_load_options: [], **params)
    target_data_batch = _safe_query(**params)

    # If any pre-load data is requested, fetch it with the batch
    eager_load_data = if eager_load_options.present?
      _safe_fetch_eager_load_data(target_data_batch, Array(eager_load_options))
    else
      {}
    end

    results_array = []
    cursor = nil
    if target_data_batch.present?
      results_array = target_data_batch.map do |target_data|
        new(target_data: target_data, eager_load_data: eager_load_data)
      end
      cursor = target_data_batch.cursor
    end

    PagedResult.new(results_array, cursor)
  end

  def find_by(eager_load_options: [], **params)
    query(eager_load_options: eager_load_options, **params).first
  end

  def find_by!(eager_load_options: [], **params)
    result = query(eager_load_options: eager_load_options, **params).first
    unless result.present?
      raise Target::NotFoundError, "Target of type #{self} with params #{params} not found"
    end
    result
  end

  # Private methods called by public queryable methods
  # ==================================================

  def _safe_fetch_target_data(token)
    Target.check_permission!(
      target_type: Target.type_of(self),
      capability: TargetCapability::READ,
    )
    _with_error_handling(nil) { _fetch_target_data(token) }
  end

  def _safe_fetch_target_data_batch(tokens)
    Target.check_permission!(
      target_type: Target.type_of(self),
      capability: TargetCapability::READ,
    )
    _with_error_handling([]) { _fetch_target_data_batch(tokens) }
  end

  def _safe_query(**params)
    Target.check_permission!(
      target_type: Target.type_of(self),
      capability: TargetCapability::SEARCH,
    )
    _with_error_handling { _query(**params) }
  end

  def _safe_fetch_eager_load_data(target_data_batch, eager_load_options)
    Target.check_permission!(
      target_type: Target.type_of(self),
      capability: TargetCapability::READ,
    )
    _with_error_handling { _fetch_eager_load_data(target_data_batch, eager_load_options) }
  end

  def _with_error_handling(not_found_fallback = :raise, &blk)
    blk.call
  rescue BaseClient::ForbiddenError => error
    raise Target::ForbiddenError,
      I18n.t('target.forbidden_client_error',
        target: Target.type_of(self).humanize.pluralize,
        message: error.message,
      )
  rescue BaseClient::BadRequest => error
    raise Target::InvalidRequestError, error.message
  rescue BaseClient::RecordNotFound => error
    if not_found_fallback == :raise
      raise Target::NotFoundError, error.message
    else
      not_found_fallback
    end
  end
end
