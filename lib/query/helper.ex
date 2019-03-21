defmodule Query.Helper do
  def is_field?(value) do
    cond do
      is_number(value) ->
        false

      String.starts_with?(value, "$") == true ->
        true

      true ->
        false
    end
  end
end
