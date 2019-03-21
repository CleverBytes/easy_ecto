defmodule TestModel.Where do
  @moduledoc ~S"""
  The dummy test model that is not stored in the database.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @fields [:first_name, :last_name, :personal_id]
  @primary_key false

  schema "" do
    field(:first_name, :string, virtual: true)
    field(:personal_id, :integer, virtual: true)
    field(:last_name, :string, virtual: true)
  end

  def changeset(data) when is_map(data) do
    %__MODULE__{}
    |> cast(data, @fields)
    |> apply_changes()
  end
end
