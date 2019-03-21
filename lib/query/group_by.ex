defmodule Query.GroupBy do
  @moduledoc false
  defmacro __using__(_options) do
    quote location: :keep do
      @doc false
      def build_group_by(queryable, opts_group_by) do
        if opts_group_by == nil do
          queryable
        else
          queryable
          # TODO:
        end
      end
    end
  end
end
