defmodule Query.Where do
  import Ecto.Query

  def build(queryable, opts_where) do
    if opts_where == nil do
      queryable
    else
      Enum.reduce(opts_where, queryable, fn {k, v}, queryable ->
        query_where(queryable, {k, v})
      end)
    end
  end

  defp query_where(queryable, {k, map_cond}) when is_map(map_cond) do
    queryable =
      case k do
        "$or" ->
          dynamics =
            Enum.reduce(map_cond, false, fn {key, condition}, dynamics ->
              case condition do
                %{"$like" => value} ->
                  # query = from q in CustomerModel, where: like(fragment("(?)::TEXT", q.id), "%1")
                  dynamic(
                    [q],
                    like(fragment("(?)::TEXT", field(q, ^String.to_existing_atom(key))), ^value) or
                      ^dynamics
                  )

                %{"$ilike" => value} ->
                  dynamic(
                    [q],
                    ilike(fragment("(?)::TEXT", field(q, ^String.to_existing_atom(key))), ^value) or
                      ^dynamics
                  )

                %{"$lt" => value} ->
                  if Query.Helper.is_field?(value) do
                    dynamic(
                      [q],
                      field(q, ^String.to_existing_atom(key)) <
                        field(q, ^String.to_existing_atom(value)) or ^dynamics
                    )
                  else
                    dynamic(
                      [q],
                      field(q, ^String.to_existing_atom(key)) < ^value or ^dynamics
                    )
                  end

                %{"$lte" => value} ->
                  if Query.Helper.is_field?(value) do
                    dynamic(
                      [q],
                      field(q, ^String.to_existing_atom(key)) <=
                        field(q, ^String.to_existing_atom(value)) or ^dynamics
                    )
                  else
                    from(q in queryable, where: field(q, ^String.to_existing_atom(key)) <= ^value)
                  end

                %{"$gt" => value} ->
                  if Query.Helper.is_field?(value) do
                    dynamic(
                      [q],
                      field(q, ^String.to_existing_atom(key)) >
                        field(q, ^String.to_existing_atom(value)) or ^dynamics
                    )
                  else
                    dynamic(
                      [q],
                      field(q, ^String.to_existing_atom(key)) > ^value or ^dynamics
                    )
                  end

                %{"$gte" => value} ->
                  if Query.Helper.is_field?(value) do
                    dynamic(
                      [q],
                      field(q, ^String.to_existing_atom(key)) >=
                        field(q, ^String.to_existing_atom(value)) or ^dynamics
                    )
                  else
                    dynamic(
                      [q],
                      field(q, ^String.to_existing_atom(key)) >= ^value or ^dynamics
                    )
                  end

                condition when not is_list(condition) and not is_map(condition) ->
                  dynamic(
                    [q],
                    field(q, ^String.to_existing_atom(key)) == ^condition or ^dynamics
                  )

                _whatever ->
                  dynamics
              end
            end)

          queryable = from(q in queryable, where: ^dynamics)

        "$not" ->
          queryable

        _whatever ->
          queryable
      end

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
          if Query.Helper.is_field?(value) do
            from(
              q in queryable,
              where:
                field(q, ^String.to_existing_atom(k)) < field(q, ^String.to_existing_atom(value))
            )
          else
            from(q in queryable, where: field(q, ^String.to_existing_atom(k)) < ^value)
          end

        "$lte" ->
          if Query.Helper.is_field?(value) do
            from(
              q in queryable,
              where:
                field(q, ^String.to_existing_atom(k)) <= field(q, ^String.to_existing_atom(value))
            )
          else
            from(q in queryable, where: field(q, ^String.to_existing_atom(k)) <= ^value)
          end

        "$gt" ->
          if Query.Helper.is_field?(value) do
            from(
              q in queryable,
              where:
                field(q, ^String.to_existing_atom(k)) > field(q, ^String.to_existing_atom(value))
            )
          else
            from(q in queryable, where: field(q, ^String.to_existing_atom(k)) > ^value)
          end

        "$gte" ->
          if Query.Helper.is_field?(value) do
            from(
              q in queryable,
              where:
                field(q, ^String.to_existing_atom(k)) >= field(q, ^String.to_existing_atom(value))
            )
          else
            from(q in queryable, where: field(q, ^String.to_existing_atom(k)) >= ^value)
          end

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
end
