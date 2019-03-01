module Types
  class QueryType < Types::BaseObject
    # Add root-level fields here.
    # They will be entry points for queries on your schema.
    field :payment, Types::PaymentType, null: false do
      argument :id, ID, required: true
    end

    def payment(params)
      Payment.lookup(params[:id])
    end
  end
end
