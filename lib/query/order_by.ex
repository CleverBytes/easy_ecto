defmodule Query.OrderBy do
  @moduledoc false
  defmacro __using__(_options) do
    quote location: :keep do
      @doc """
      Build up a dynamic `order_by` asc or desc query.
      ## Parameters

        - Schema_name: Schema name that represents your database model.
        - Opts: %{"$order" => %{"field" => "$desc"}}.
      ## Examples

          iex> build(schema_name, opts)
          #Ecto.Query<from j in TestModel.Join, order_by: [desc: j.field]>

      """
      def build_order_by(queryable, opts_order_by) do
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
    end
  end
end
