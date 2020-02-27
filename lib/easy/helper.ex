defmodule EASY.Helper do
  @moduledoc false

  # TODO: read http://michal.muskala.eu/2017/07/30/configuring-elixir-libraries.html#recommendations-for-library-authors
  # TODO: read http://michal.muskala.eu/2017/02/10/error-handling-in-elixir-libraries.html
  require Ecto.Query
  @min_limit 0
  @max_limit Application.get_env(:easy_ecto, :repo)[:max_limit]
  @default_limit Application.get_env(:easy_ecto, :repo)[:default_limit]

  @min_skip 0
  @default_skip 0

  def get_skip_value(params) do
    {skip, params} = Keyword.pop(params, :skip, @min_skip)
    skip = to_int(skip)
    skip = if skip > @default_skip, do: skip, else: @default_skip
    {skip, params}
  end

  def get_limit_value(params) do
    {limit, params} = Keyword.pop(params, :limit, @default_limit)
    limit = to_int(limit)
    limit = if limit > @min_limit, do: limit, else: @min_limit
    limit = if limit > @max_limit, do: @max_limit, else: limit
    {limit, params}
  end

  def to_struct(kind, attrs) do
    struct = struct(kind)

    Enum.reduce(Map.to_list(struct), struct, fn {k, _}, acc ->
      case Map.fetch(attrs, Atom.to_string(k)) do
        {:ok, v} -> %{acc | k => v}
        :error -> acc
      end
    end)
  end

  defp schema_fields(%{from: {_source, schema}}, queryable) when schema != nil,
       do: schema.__schema__(:fields)

  defp schema_fields(_query), do: nil
  defp schema_fields(_query, queryable), do: queryable.__schema__(:fields)

  def field_exists?(queryable, column) do
    query = Ecto.Queryable.to_query(queryable)
    fields = schema_fields(query, queryable)

    if fields == nil do
      true
    else
      Enum.member?(fields, column)
    end
  end

  defp to_int(i) when is_integer(i), do: i

  defp to_int(s) when is_binary(s) do
    case Integer.parse(s) do
      {i, _} -> i
      :error -> :error
    end
  end

  def get_limit(limit_param) do
    limit = to_int(limit_param || @default_limit)
    limit = if limit > @min_limit, do: limit, else: @min_limit
    if limit > @max_limit, do: @max_limit, else: limit
  end

  def deep_merge(left, right) do
    Map.merge(left, right, &deep_resolve/3)
  end

  # Key exists in both maps, and both values are maps as well.
  # These can be merged recursively.
  defp deep_resolve(_key, left = %{}, right = %{}) do
    deep_merge(left, right)
  end

  # Key exists in both maps, but at least one of the values is
  # NOT a map. We fall back to standard merge behavior, preferring
  # the value on the right.
  defp deep_resolve(_key, _left, right) do
    right
  end

  def fields(select) do
    map = select
    fields = map["$fields"]
    Enum.map(fields, &String.to_existing_atom/1)
  end
end
