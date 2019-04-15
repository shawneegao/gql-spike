module Types::TargetType
  include Types::BaseInterface
    field :id, ID, null: false,
      description: <<~DOC
        Everything has an Id! 
      DOC
end