defmodule Query.Helper do
  @moduledoc false
  def is_field?(value) do
    cond do
      is_number(value) ->
        false

      String.starts_with?(value, "$") == true ->
        true

      true ->
        false
    end
  end

  def is_map?(value) do
    cond do
      is_map(value) ->
        true

      true ->
        false
    end
  end

  def associations(model, relation_name, fields, assoc_fields) do
    case model.__schema__(:association, relation_name) do
      %Ecto.Association.Has{
        owner: _owner,
        owner_key: owner_key,
        related: _related,
        related_key: _related_key
      } ->
        fields ++ [owner_key] ++ [{relation_name, Enum.map(assoc_fields, &String.to_existing_atom/1)}]

      %Ecto.Association.BelongsTo{
        owner: _owner,
        owner_key: owner_key,
        related: _related,
        related_key: _related_key
      } ->
        fields ++ [owner_key] ++ [{relation_name, Enum.map(assoc_fields, &String.to_existing_atom/1)}]
    end
  end

  defp replacement_for(key, tuple) do
    map = Enum.into(tuple, %{})

    if Map.has_key?(map, to_string(key)) do
      tuple
      |> Enum.find(fn {x, _} -> x == to_string(key) end)
      |> elem(1)
    else
      key
    end
  end

  def replace_keys(map, tuple) do
    for {k, v} <- map, into: %{}, do: {replacement_for(k, tuple), v}
  end

  def field_exists(queryable, opts_select, model) do
    queryable_schema_fields = queryable.__schema__(:fields)
    model_schema_fields = model.__schema__(:fields)
    values = Map.values(opts_select)
    map_keys = Enum.map(values, &Map.keys/1)
    single_list = Enum.at(map_keys, 0)
    asso_model = single_list -- ["$fields"]
    asso_model_name = Enum.at(asso_model, 0)
    queryable_fields = opts_select["$select"]["$fields"]
    model_fields = opts_select["$select"][asso_model_name]
    queryable_f_exists = Enum.map(queryable_fields, &String.to_atom/1) -- queryable_schema_fields
    model_f_exists = Enum.map(model_fields, &String.to_atom/1) -- model_schema_fields
    queryable_f_exists ++ model_f_exists
  end
end
