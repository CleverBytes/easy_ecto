defmodule EASY.Query do
  @moduledoc """

  """

  import Ecto.Query

  # TODO: Should return {:ok, query}
  def build(queryable, query_opts) do
    model =
      if is_atom(queryable) do
        queryable
      else
        {_table, model} = queryable.from
        model
      end

    build_query(queryable, query_opts, model)
  end

  defp build_query(queryable, opts, model) do
    # TODO: LIMP: first confirm the field exist in the schema
    # TODO: LIMP: check for queryable, filterable etc
    # TODO: LIMP: With pipes here
    queryable
    |> build_select(opts["$select"], model)
    |> build_maximum(opts["$max"])
    |> build_minimum(opts["$min"])
    |> build_where(opts["$where"])
    |> build_include(opts["$include"], model)
    |> build_order_by(opts["$order"])
    |> build_group_by(opts["$group"])
  end

  defp build_where(queryable, opts_where) do
    # TODO: Test all these implementations with different order and values

    # Examples and TODOs

    # $and: {a: 5}           // AND (a = 5)
    # $and: [
    #   { id: [1,2,3] },
    #   { id: { $gt: 10 } }
    # ]

    # $or: [{a: 5}, {a: 6}]  // (a = 5 OR a = 6)
    # $or: [
    #   { id: [1,2,3] },
    #   { id: { $gt: 10 } }
    # ]

    # TODO: For future release
    # $lt: 10,               // id < 10
    # $lte: 10,              // id <= 10
    # $gte: 6,               // id >= 6
    # $gt: 6,                // id > 6
    # where: {'id': {$gt: 25}}
    # $or: [
    #   { id: [1,2,3] },
    #   { id: { $gt: 10 } }
    # ]

    # $ne: 20,               // id != 20
    # $or: [
    #   { id: [1,2,3] },
    #   { id: { $ne: 10 } }
    # ]

    # TODO: For future release
    # $between: [6, 10],     // BETWEEN 6 AND 10
    # $notBetween: [11, 15], // NOT BETWEEN 11 AND 15

    # $in: [1, 2],           // IN [1, 2]
    # $notIn: [1, 2],        // NOT IN [1, 2]
    # $like: '%hat',         // LIKE '%hat'
    # $notLike: '%hat'       // NOT LIKE '%hat'
    # $iLike: '%hat'         // ILIKE '%hat' (case insensitive)  (PG only)
    # $notILike: '%hat'      // NOT ILIKE '%hat'  (PG only)

    # TODO: For future release
    # $overlap: [1, 2]       // && [1, 2] (PG array overlap operator)

    # $contains: [1, 2]      // @> [1, 2] (PG array contains operator)
    # $contained: [1, 2]     // <@ [1, 2] (PG array contained by operator)
    # $any: [2,3]            // ANY ARRAY[2, 3]::INTEGER (PG only)
    # TODO: Move to function with guard
    if opts_where == nil do
      queryable
    else
      Enum.reduce(opts_where, queryable, fn {k, v}, queryable ->
        query_where(queryable, {k, v})
      end)
    end
  end

  # TODO: add examples of where queries which this method is going handle
  # Example
  # "where": {
  #  "notLikeField": {
  #    "$notLike": "%abc%"
  # },
  #  "notInField": {
  #    "$notIn": [
  #      5,
  #      10
  #    ]
  #  },
  #  "notILikeField": {
  #   "$notILike": "%abc%"
  #  },
  #  "likeField": {
  #    "$like": "%abc%"
  #  },
  #  "lessThanField": {
  #    "$lt": 10
  #  },
  #  "lessThanEqualField": {
  #    "$lte": 10
  #  },
  #  "inField": {
  #    "$in": [
  #      5,
  #      10
  #    ]
  #  },
  #  "iLikeField": {
  #    "$iLike": "%abc%"
  #  },
  #  "geaterThanField": {
  #    "$gt": 10
  #  },
  #  "geaterThanEqualField": {
  #    "$gte": 10
  #  },
  #  "equal": "test",
  #  "betweenNotField": {
  #    "$notBetween": [
  #      5,
  #      10
  #    ]
  #  },
  #  "betweenField": {
  #    "$between": [
  #      5,
  #      10
  #    ]
  #  }
  # }
  defp query_where(queryable, {k, map_cond}) when is_map(map_cond) do
    Enum.reduce(map_cond, queryable, fn {key, value}, queryable ->
      case key do
        "$like" ->
          from(q in queryable, where: like(field(q, ^String.to_existing_atom(k)), ^value))

        "$iLike" ->
          from(q in queryable, where: ilike(field(q, ^String.to_existing_atom(k)), ^value))

        "$notLike" ->
          from(q in queryable, where: not like(field(q, ^String.to_existing_atom(k)), ^value))

        "$notILike" ->
          from(q in queryable, where: not ilike(field(q, ^String.to_existing_atom(k)), ^value))

        "$lt" ->
          from(q in queryable, where: field(q, ^String.to_existing_atom(k)) < ^value)

        "$lte" ->
          from(q in queryable, where: field(q, ^String.to_existing_atom(k)) <= ^value)

        "$gt" ->
          from(q in queryable, where: field(q, ^String.to_existing_atom(k)) > ^value)

        "$gte" ->
          from(q in queryable, where: field(q, ^String.to_existing_atom(k)) >= ^value)

        "$between" ->
          from(
            q in queryable,
            where:
              field(q, ^String.to_existing_atom(k)) > ^Enum.min(value) and
                field(q, ^String.to_existing_atom(k)) < ^Enum.max(value)
          )

        "$notBetween" ->
          from(
            q in queryable,
            where:
              field(q, ^String.to_existing_atom(k)) > ^Enum.min(value) or
                field(q, ^String.to_existing_atom(k)) < ^Enum.max(value)
          )

        "$in" ->
          from(q in queryable, where: field(q, ^String.to_existing_atom(k)) in ^value)

        "$notIn" ->
          from(q in queryable, where: field(q, ^String.to_existing_atom(k)) not in ^value)

        "$not" ->
          # TODO:
          # Example
          # "id": {
          # TODO: implement now
          # 	"$not": {
          # 		"$eq": [1,2,3],
          # 		"$gt": 10,
          # 		"$lt": 1
          # 	}
          # }

          # Example
          # "$not": {
          # 	"id": [
          # 		1,2,3,
          #    ],
          #   "customer_rating": null,
          # 	"$gt": { "id": 10 }
          #  }
          queryable

        "$or" ->
          # TODO:
          # Example
          # "id": {
          # 	"$not": [
          # 		[1,2,3],
          # 		{ "$gt": 10 }
          # 	]
          # }

          # Example
          # "$or": {
          # 	"id": [
          # 		1,2,3,
          #    ],
          # 	"$gt": { "id": 10 }
          #  }
          queryable

        _ ->
          # TODO:
          queryable
      end
    end)
  end

  defp query_where(queryable, {k, map_cond}) when is_nil(map_cond) do
    from(q in queryable, where: is_nil(field(q, ^String.to_existing_atom(k))))
  end

  defp query_where(queryable, {k, map_cond}) when not is_list(map_cond) do
    from(q in queryable, where: field(q, ^String.to_existing_atom(k)) == ^map_cond)
  end

  defp query_where(queryable, {k, map_cond}) when is_list(map_cond) and k == "$notNull" do
    Enum.reduce(map_cond, queryable, fn key, queryable ->
      from(q in queryable, where: not is_nil(field(q, ^String.to_existing_atom(key))))
    end)
  end

  defp build_include(queryable, opts_include, model) do
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
            |> build_where(value["$where"])
            |> build_order_by(value["$order"])
            |> limit([q], ^EASY.Helper.get_limit(value["$limit"]))
            |> offset([q], ^(value["$offset"] || 0))

          case value["$join"] do
            "$right" ->
              from(
                q in queryable,
                right_join: a in assoc(q, ^relation_name),
                preload: [{^relation_name, ^include_kwery}]
              )

            "$left" ->
              from(
                q in queryable,
                left_join: a in assoc(q, ^relation_name),
                preload: [{^relation_name, ^include_kwery}]
              )

            "$inner" ->
              from(
                q in queryable,
                inner_join: a in assoc(q, ^relation_name),
                preload: [{^relation_name, ^include_kwery}]
              )

            "$full" ->
              from(
                q in queryable,
                full_join: a in assoc(q, ^relation_name),
                preload: [{^relation_name, ^include_kwery}]
              )

            _whatever ->
              from(
                q in queryable,
                join: a in assoc(q, ^relation_name),
                preload: [{^relation_name, ^include_kwery}]
              )
          end
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

  defp build_order_by(queryable, opts_order_by) do
    if opts_order_by == nil do
      queryable
    else
      Enum.reduce(opts_order_by, queryable, fn {field, format}, queryable ->
        if format == "$desc" do
          from(
            queryable,
            order_by: [
              desc: ^String.to_existing_atom(field)
            ]
          )
        else
          from(
            queryable,
            order_by: [
              asc: ^String.to_existing_atom(field)
            ]
          )
        end
      end)
    end
  end

  defp build_group_by(queryable, opts_group_by) do
    if opts_group_by == nil do
      queryable
    else
      queryable
      # TODO:
    end
  end

  defp build_select(queryable, opts_select, model) do
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
                  fields ++ [owner_key] ++ [{relation_name, Enum.map(value, &String.to_existing_atom/1)}]

                %Ecto.Association.BelongsTo{
                  owner: _owner,
                  owner_key: owner_key,
                  related: _related,
                  related_key: _related_key
                } ->
                  fields ++ [owner_key] ++ [{relation_name, Enum.map(value, &String.to_existing_atom/1)}]
              end
            end
          end)

        from(q in queryable, select: map(q, ^Enum.uniq(fields)))
    end
  end

  defp build_maximum(queryable, opts_max) do
    case opts_max do
      nil ->
        queryable

      maximum when is_list(maximum) ->
        Enum.reduce(opts_max, queryable, fn k, _v ->
          from(
            q in queryable,
            order_by: [
              desc: ^String.to_existing_atom(k)
            ],
            limit: 1
          )
        end)
    end
  end

  defp build_minimum(queryable, opts_min) do
    case opts_min do
      nil ->
        queryable

      minimum when is_list(minimum) ->
        Enum.reduce(opts_min, queryable, fn k, _v ->
          from(
            q in queryable,
            order_by: [
              asc: ^String.to_existing_atom(k)
            ],
            limit: 1
          )
        end)
    end
  end
end
