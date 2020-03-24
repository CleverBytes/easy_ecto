defmodule EASY.Query do
  @moduledoc """
      Provide methods for dynamic Query
  """

  @default_query_opts %{
    "$find" => "$all",
    "$where" => nil,
    # TODO: $max and $min should be part of select as in example docs
    "$max" => nil,
    "$min" => nil,
    "$include" => nil,
    "$select" => nil,
    "$order" => nil,
    # TODO: $group should be part of select
    "$group" => nil,
    "$skip" => 0,
    "$limit" => Application.get_env(:easy_ecto, :repo)[:default_limit]
  }

  @repo Application.get_env(:easy_ecto, :repo)[:query_repo]
  use EASY.Paginator, repo: @repo
  # import Query.Where, only: [build_where: 2] # import and use like this if without defmacro
  # import Query.OrderBy, only: [build_order_by: 2]
  # import Query.Include, only: [build_include: 3]
  # import Query.Select, only: [build_select: 3]
  # import Query.Join, only: [build_join: 2]
  # import Query.GroupBy, only: [build_group_by: 2]

  import Ecto.Query
  use Query.Where
  use Query.OrderBy
  use Query.Include
  use Query.Select
  use Query.Join
  use Query.Distinct
  # TODO: Should return {:ok, query}
  @doc """
  Call the `respective query method` depending on the params.
  ## Parameters

    - Schema_name: Schema name that represents your database model.
    - Opts: which is a map %{}
  ## Examples

      iex> build(schema_name, %{})
      #Ecto.Query<>

  """
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
    queryable
    |> build_select(opts["$select"], model,opts["$group"])
    |> build_where(opts["$where"])
    |> build_join(opts["$join"], "$join")
    |> build_join(opts["$right_join"], "$right_join")
    |> build_join(opts["$left_join"], "$left_join")
    |> build_join(opts["$inner_join"], "$inner_join")
    |> build_join(opts["$full_join"], "$full_join")
    |> build_include(opts["$include"], model)
    |> build_order_by(opts["$order"])
    |> build_distinct(opts["$distinct"])
  end

  @doc false
  def fetch(queryable, query_opts, role \\nil, res \\nil, action \\nil) do
    opts = EASY.Helper.deep_merge(@default_query_opts, query_opts)

    acl_rule = if (is_nil(role)) do
      nil
    else
      Acl.hasAccess(role, "read", res, action)
    end

    queryable = case acl_rule do
      {:ok, rule} ->
      where_clause=if(opts["$where"] != nil) do
          Map.merge(opts["$where"], rule["$where"])
        else
           rule["$where"]
        end
        options = Map.merge(opts, %{"$where" => where_clause})
        EASY.Query.build(queryable, opts)
      _ ->
        false
    end


    case opts["$find"] do
      "$one" when queryable != false ->
        {:ok, @repo.one(Ecto.Query.limit(queryable, 1))}

      "$all" when queryable != false ->
        {:ok, new(queryable, skip: opts["$skip"], limit: opts["$limit"])}

      nil ->
        {:error, "Method not found"}

      _ ->
        {:error, "Method not found"}
    end
  end

#  def fetch(queryable, query_opts, role \\nil, res \\nil, action \\nil) do
#    opts = EASY.Helper.deep_merge(@default_query_opts, query_opts)
#    queryable = EASY.Query.build(queryable, opts)
#
#    case opts["$find"] do
#      "$one" ->
#        {:ok, @repo.one(Ecto.Query.limit(queryable, 1))}
#
#      "$all" ->
#        {:ok, new(queryable, skip: opts["$skip"], limit: opts["$limit"])}
#
#      nil ->
#        {:error, "Method not found"}
#
#      _ ->
#        {:error, "Method not found"}
#    end
#
#  end
end
