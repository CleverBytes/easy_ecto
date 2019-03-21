defmodule Query.OrderBy do
  import Ecto.Query

  def build(queryable, opts_order_by) do
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
