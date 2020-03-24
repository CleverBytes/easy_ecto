defmodule Query.Distinct do
  @moduledoc false
  defmacro __using__(_options) do
    quote location: :keep do
      @doc false
      def build_distinct(queryable, opts_group_by) do
        IO.inspect(queryable)
        IO.inspect(opts_group_by )
        if opts_group_by == nil do
          queryable
        else
          asd=queryable |> distinct(^String.to_existing_atom(opts_group_by))
#              |> group_by(^String.to_existing_atom(opts_group_by))
          IO.inspect(asd)
          asd
        end
      end
    end
  end
end
