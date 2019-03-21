defmodule Query.Include do
  import Ecto.Query

  def build(queryable, opts_include, model) do
    case opts_include do
      nil ->
        queryable

      include when is_map(include) ->
        Enum.reduce(include, queryable, fn {key, value}, queryable ->
          relation_name = String.to_existing_atom(key)

          %{
            owner: _owner,
            owner_key: _owner_key,
            related: related_model,
            related_key: _related_key
          } =
            case model.__schema__(:association, relation_name) do
              %Ecto.Association.Has{
                owner: owner,
                owner_key: owner_key,
                related: related,
                related_key: related_key
              } ->
                %{owner: owner, owner_key: owner_key, related: related, related_key: related_key}

              %Ecto.Association.BelongsTo{
                owner: owner,
                owner_key: owner_key,
                related: related,
                related_key: related_key
              } ->
                %{owner: owner, owner_key: owner_key, related: related, related_key: related_key}
            end

          include_kwery =
            related_model
            |> Query.Where.build(value["$where"])
            |> Query.OrderBy.build(value["$order"])
            |> limit([q], ^Qber.Paginator.get_limit(value["$limit"]))
            |> offset([q], ^(value["$offset"] || 0))

          join = String.replace(value["$join"] || "$inner", "$", "") |> String.to_atom()

          queryable |> join(join, [q], jn in assoc(q, ^relation_name))
          |> preload([q, ..., jt], [{^relation_name, ^include_kwery}])
        end)

      include when is_binary(include) ->
        from(
          q in queryable,
          join: a in assoc(q, ^String.to_existing_atom(include)),
          preload: [^String.to_existing_atom(include)]
        )

      include when is_list(include) ->
        # TODO: implement logic for the
        Enum.reduce(include, queryable, fn model, queryable ->
          case model do
            m when is_map(m) ->
              # TODO:
              queryable

            m when is_binary(m) ->
              from(
                q in queryable,
                join: a in assoc(q, ^String.to_existing_atom(m)),
                preload: [^String.to_existing_atom(m)]
              )
          end
        end)
    end
  end
end
