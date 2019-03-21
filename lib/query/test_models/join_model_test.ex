defmodule TestModel.Join do
  @moduledoc ~S"""
  The dummy test model that is not stored in the database.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @fields [:public_name, :personal_name, :pass]
  @primary_key false

  schema "" do
    field(:public_name, :string, virtual: true)
    field(:pass, :integer, virtual: true)
    field(:personal_name, :string, virtual: true)
    belongs_to(:example, TestModel.Where, define_field: false, foreign_key: :first_name)
  end

  def changeset(data) when is_map(data) do
    %__MODULE__{}
    |> cast(data, @fields)
    |> apply_changes()
  end
end
