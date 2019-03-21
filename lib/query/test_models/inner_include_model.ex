defmodule InnerIncludeModel.Child do
  @moduledoc ~S"""
  The dummy test model that is not stored in the database.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @fields [:public_name, :personal_name, :count]
  @primary_key false

  schema "" do
    field(:public_name, :string, virtual: true)
    field(:count, :integer, virtual: true)
    field(:personal_name, :string, virtual: true)
    belongs_to(:inner_include, TestModel.Join, define_field: false, foreign_key: :public_name)
  end

  def changeset(data) when is_map(data) do
    %__MODULE__{}
    |> cast(data, @fields)
    |> apply_changes()
  end
end
