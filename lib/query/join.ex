defmodule Query.Join do
  import Ecto.Query

  # opts =
  #    %{ "provider_companies" => %{
  #     "$on_field" => "id",
  #     "$on_join_table_field" => "provider_id",
  #     "$select" => ["id"]
  #   }}
  # queryable = Qber.V1.ProviderModel
  # Query.Join.build(queryable, opts, "$right_join")
  # from p in Qber.V1.ProviderModel, join: pc in "provider_companies"
  # , where: pc.provider_id == p.id, select: {map(p, [:id, {"provider_companies", [:id]}]), map(pc, [:id])}

  def build(queryable, opts, join_type \\ "$join") do
    case opts do
      nil ->
        queryable

      _opts ->
        Enum.reduce(opts, queryable, fn {join_key, join_opts}, queryable ->
          join_table = join_opts["$table"] || join_key

          join =
            String.replace(join_type, "_join", "") |> String.replace("$", "") |> String.to_atom()

          queryable =
            if join_opts["$on_type"] == "$not_eq" do
              queryable =
                queryable
                |> join(
                  join,
                  [q],
                  jt in ^join_table,
                  field(q, ^String.to_atom(join_opts["$on_field"])) !=
                    field(jt, ^String.to_atom(join_opts["$on_join_table_field"]))
                )
            else
              queryable =
                queryable
                |> join(
                  join,
                  [q],
                  jt in ^join_table,
                  field(q, ^String.to_atom(join_opts["$on_field"])) ==
                    field(jt, ^String.to_atom(join_opts["$on_join_table_field"]))
                )
            end

          _select(queryable, join_opts, join_key)
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
end
