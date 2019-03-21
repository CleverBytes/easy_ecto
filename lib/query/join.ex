defmodule Query.Join do
  @moduledoc false
  defmacro __using__(_options) do
    quote location: :keep do
      # opts = %{
      #     "$right_join" =>
      #    %{ "provider_companies" => %{
      #     "$on_field" => "id",
      #     "$on_join_table_field" => "provider_id",
      #     "$select" => ["id"]
      #   }}}
      # queryable = Qber.V1.ProviderModel
      # Query.Join.build(queryable, opts, "$right_join")
      # from p in Qber.V1.ProviderModel, join: pc in "provider_companies"
      # , where: pc.provider_id == p.id, select: {map(p, [:id, {"provider_companies", [:id]}]), map(pc, [:id])}

      @doc """
      Build up a dynamic `join` query and spcify  the fields which will be selected as a map .
      ## Parameters

        - Schema_name: Schema name that represents your database model.
        - Opts: %{ "$right_join" => %{ "assoc_model" => %{ "$on_field" => "field", "$on_join_table_field" => "field", "$select" => ["field"]}}}

      ## Examples

          iex> build(schema_name, opts)
          #Ecto.Query<from j in model, right_join: e in "assoc_model",
          on: j.field == e.field, select: merge(j, map(e, [:field]))>
      """
      def build_join(queryable, opts, join_type \\ "$join") do
        case opts do
          nil ->
            queryable

          _opts ->
            Enum.reduce(opts, queryable, fn {join_key, join_opts}, queryable ->
              join_table = join_opts["$table"] || join_key

              join =
                String.replace(join_type, "_join", "")
                |> String.replace("$", "")
                |> String.to_atom()

              queryable =
                case join_opts["$on_type"] do
                  "$not_eq" ->
                    queryable
                    |> join(
                      join,
                      [q],
                      jt in ^join_table,
                      field(q, ^String.to_atom(join_opts["$on_field"])) !=
                        field(jt, ^String.to_atom(join_opts["$on_join_table_field"]))
                    )

                  "$in_x" ->
                    queryable
                    |> join(
                      join,
                      [q],
                      jt in ^join_table,
                      field(q, ^String.to_atom(join_opts["$on_field"])) in field(
                        jt,
                        ^String.to_atom(join_opts["$on_join_table_field"])
                      )
                    )

                  "$in" ->
                    queryable
                    |> join(
                      join,
                      [q],
                      jt in ^join_table,
                      field(jt, ^String.to_atom(join_opts["$on_join_table_field"])) in field(
                        q,
                        ^String.to_atom(join_opts["$on_field"])
                      )
                    )

                  _whatever ->
                    queryable
                    |> join(
                      join,
                      [q],
                      jt in ^join_table,
                      field(q, ^String.to_atom(join_opts["$on_field"])) ==
                        field(jt, ^String.to_atom(join_opts["$on_join_table_field"]))
                    )
                end

              queryable =
                if join_opts["$where"] == nil do
                  queryable
                else
                  EASY.Query.build_where(queryable, join_opts["$where"], [binding: :last, ilike: :on])
                end

              queryable = order(queryable, join_opts["$order"])
              queryable = _select(queryable, join_opts, join_key)
            end)
        end
      end

      defp _select(queryable, join_opts, join_table) do
        case join_opts["$select"] do
          nil ->
            queryable

          select when is_list(select) ->
            # Below syntax doesn't support ... in binding
            # queryable |> select_merge([q, c], (%{location_dest_zone: map(c, ^select_atoms)}))

            # TODO: use dynamics to build queries whereever possible
            # dynamic = dynamic([q, ..., c], c.id == 1)
            # from query, where: ^dynamic

            select_atoms = Enum.map(select, &String.to_atom/1)

            case join_table do
              "customer" ->
                from([q, ..., c] in queryable, select_merge: %{customer: map(c, ^select_atoms)})

              "provider" ->
                from([q, ..., c] in queryable, select_merge: %{provider: map(c, ^select_atoms)})

              "companies" ->
                from([q, ..., c] in queryable, select_merge: %{companies: map(c, ^select_atoms)})

              "location_dest_zone" ->
                from(
                  [q, ..., c] in queryable,
                  select_merge: %{location_dest_zone: map(c, ^select_atoms)}
                )

              "service" ->
                from([q, ..., c] in queryable, select_merge: %{service: map(c, ^select_atoms)})

              "services" ->
                from([q, ..., c] in queryable, select_merge: %{services: map(c, ^select_atoms)})

              "current_zone" ->
                from(
                  [q, ..., c] in queryable,
                  select_merge: %{current_zone: map(c, ^select_atoms)}
                )

              "transport_type" ->
                from(
                  [q, ..., c] in queryable,
                  select_merge: %{transport_type: map(c, ^select_atoms)}
                )

              "provider_companies" ->
                from(
                  [q, ..., c] in queryable,
                  select_merge: %{provider_companies: map(c, ^select_atoms)}
                )

              _whatever ->
                from([q, ..., c] in queryable, select_merge: map(c, ^select_atoms))
            end

            # from([q, ..., c] in queryable, select_merge: %{ ^join_table => map(c, ^Enum.map(select, &String.to_atom/1))})
            # from([q, ..., c] in queryable, select_merge: map(c, ^Enum.map(select, &String.to_atom/1)))
        end
      end

      defp order(queryable, opts_order_by) do
        if opts_order_by == nil do
          queryable
        else
          Enum.reduce(opts_order_by, queryable, fn {field, format}, queryable ->
            if format == "$desc" do
              from(
                [q, ..., c] in queryable,
                order_by: [
                  desc: field(c, ^String.to_existing_atom(field))
                ]
              )
            else
              from(
                [q, ..., c] in queryable,
                order_by: [
                  asc: field(c, ^String.to_existing_atom(field))
                ]
              )
            end
          end)
        end
      end
    end
  end
end
