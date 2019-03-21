defmodule Query.Include do
  @moduledoc false
  defmacro __using__(_options) do
    quote location: :keep do
      @doc """
      Build up a dynamic `include` query with the associated model. include the different query methods.
      ## Parameters

        - Schema_name: Schema name that represents your database model.
        - Opts: %{ "$include" => %{"assoc_model" => %{"$limit" => 10,"$order" => %{"field" => "$asc"},"$where" => %{"id" => integer} }}}}.
      ## Examples

          iex> build(schema_name, opts)
          #Ecto.Query<from j in model, join: e in assoc(j, :assoc_model),
          preload: [example: #Ecto.Query<from w in model, where: w.id == ^integer, order_by: [asc: w.field], limit: ^10, offset: ^0>]>

      """
      def build_include(queryable, opts_include, model) do
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
                    %{
                      owner: owner,
                      owner_key: owner_key,
                      related: related,
                      related_key: related_key
                    }

                  %Ecto.Association.BelongsTo{
                    owner: owner,
                    owner_key: owner_key,
                    related: related,
                    related_key: related_key
                  } ->
                    %{
                      owner: owner,
                      owner_key: owner_key,
                      related: related,
                      related_key: related_key
                    }

                  %Ecto.Association.ManyToMany{
                    owner: owner,
                    owner_key: owner_key,
                    related: related
                    # related_key: related_key
                  } ->
                    %{
                      owner: owner,
                      owner_key: owner_key,
                      related: related,
                      related_key: nil
                    }
                end

              include_kwery =
                related_model
                |> EASY.Query.build_where(value["$where"], binding: :last)
                |> EASY.Query.build_order_by(value["$order"])
                |> EASY.Query.build_include(value["$include"], related_model)
                |> limit([q], ^EASY.Helper.get_limit(value["$limit"]))
                |> offset([q], ^(value["$offset"] || 0))

              join = String.replace(value["$join"] || "$inner", "$", "") |> String.to_atom()

              queryable
              |> join(join, [q], jn in assoc(q, ^relation_name))
              |> preload([q, ..., jt], [{^relation_name, ^include_kwery}])
            end)

          include when is_binary(include) ->
            from(
              q in queryable,
              left_join: a in assoc(q, ^String.to_existing_atom(include)),
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
                    left_join: a in assoc(q, ^String.to_existing_atom(m)),
                    preload: [^String.to_existing_atom(m)]
                  )
              end
            end)
        end
      end
    end
  end
end
