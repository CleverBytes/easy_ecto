defmodule Query.Select do
  import Ecto.Query

  def build(queryable, opts_select, model) do
    case opts_select do
      nil ->
        queryable

      select when is_map(select) ->
        fields =
          Enum.reduce(select, [], fn {key, value}, fields ->
            if key == "$fields" do
              fields ++ Enum.map(value, &String.to_existing_atom/1)
            else
              relation_name = String.to_existing_atom(key)

              case model.__schema__(:association, relation_name) do
                %Ecto.Association.Has{
                  owner: _owner,
                  owner_key: owner_key,
                  related: _related,
                  related_key: _related_key
                } ->
                  fields ++
                    [owner_key] ++ [{relation_name, Enum.map(value, &String.to_existing_atom/1)}]

                %Ecto.Association.BelongsTo{
                  owner: _owner,
                  owner_key: owner_key,
                  related: _related,
                  related_key: _related_key
                } ->
                  fields ++
                    [owner_key] ++ [{relation_name, Enum.map(value, &String.to_existing_atom/1)}]
              end
            end
          end)

        from(q in queryable, select: map(q, ^Enum.uniq(fields)))
    end
  end
end
