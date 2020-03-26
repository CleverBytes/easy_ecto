defmodule EASY.Paginator do
  @moduledoc false
  @doc false
  defmacro __using__(options) do
    quote location: :keep do
      import Ecto.Query
      @repo unquote(options)[:repo]
      @doc false
      def new(query, params) do
        {skip, params} = EASY.Helper.get_skip_value(params)
        {limit, _params} = EASY.Helper.get_limit_value(params)
          data = data(query, skip, limit)
        %{
          data: data,
          meta: %{
            skip: skip,
            limit: limit,
            count: count(query)
          }
        }
      end

      defp meta(query, skip, limit) do
        %{
          skip: skip,
          limit: limit,
          count: count(query)
        }
      end

      defp data(query, skip, limit) do
        query
        |> limit([q], ^limit)
        |> offset([q], ^skip)
        |> @repo.all()
      end

      defp count(query) do
        queryable =
          query
          |> exclude(:order_by)
          |> exclude(:preload)
          |> exclude(:select)

        queryable =
          case EASY.Helper.field_exists?(queryable, :deleted_at) do
            false ->
              queryable

            true ->
              from(p in queryable, where: is_nil(p.deleted_at))
          end

        @repo.one(from(q in queryable, select: fragment("count(*)")))
      end
    end
  end
end
