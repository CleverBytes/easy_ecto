defmodule Query.Minimum do
  @moduledoc false
  defmacro __using__(_options) do
    quote location: :keep do
      def build_minimum(queryable, opts_min) do
        Enum.reduce(opts_min, queryable, fn {k, v}, queryable ->
          case v do
            nil ->
              queryable

            v when is_list(v) ->
              value = Enum.at(v, 0)

              from(
                q in queryable,
                order_by: [
                  asc: ^String.to_existing_atom(value)
                ],
                limit: 1
              )
          end
        end)
      end
    end
  end
end
