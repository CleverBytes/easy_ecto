defmodule Query.Select do
  @moduledoc false
  defmacro __using__(_options) do
    quote location: :keep do
      @doc """
      Build up a dynamic `select` query also include fields from associated model and also the foreign key.
      ## Parameters

        - Schema_name: Schema name that represents your database model.
        - Opts:  %{ "$select" => %{"$fields" => ["field1", "field2"],"assoc_model" => ["fields"]}}.
      ## Examples

          iex> build(schema_name, opts)
          #Ecto.Query<from j in model,
          select: map(j, [:field1, :field2,  {:assoc_model, [:fields]}])>

      """
      def build_select(queryable, opts_select, model, opts_group_by) do
        case opts_select do
          nil ->
            queryable

          select when is_map(select) ->
            # Getting values from the $fields
            fields_values = opts_select["$fields"]
            # Check if it is list of maps
            map = Query.Helper.is_map?(Enum.at(fields_values, 0))

            if map == true do
              # Get keys from opts_select map
              keys = Map.keys(opts_select)
              # Get values from `key`  in a list
              original_keys = Enum.map(fields_values, & &1["key"])
              # Get values from `as` in a list
              custom_keys = Enum.map(fields_values, & &1["as"])
              # Convert field values to atoms
              fields = Enum.map(original_keys, &String.to_existing_atom/1)
              # Convert custom keys to atoms
              custom_keys_atoms = Enum.map(custom_keys, &String.to_existing_atom/1)
              # Make a tupel of every `key` and `as` value [{key, as}]
              tuple = Enum.zip(original_keys, custom_keys)

              # Check if it contain assoc fields
              if Enum.count(keys) > 1 do
                assoc = tl(keys)
                        |> hd()
                # Get values of assoc table
                assoc_fields = opts_select[assoc]

                # Convert relation table in to atom
                relation_name =
                  Enum.map(tl(keys), &String.to_existing_atom/1)
                  |> hd()

                # Call the method in query helper module
                field = Query.Helper.associations(model, relation_name, fields, assoc_fields)

                query =
                  from(
                    q in queryable,
                    preload: ^relation_name,
                    # Build the query
                    select: map(q, ^Enum.uniq(field))
                  )

                # Get data from database
                result = Qserv.BaseRepo.all(query)
                # Replace orignal_keys with custom keys
                Enum.map(result, fn m -> Query.Helper.replace_keys(m, tuple) end)
              else
                # if map only contain fields(list of maps)
                query = from(q in queryable, select: map(q, ^Enum.uniq(fields)))

                result = Qserv.BaseRepo.all(query)
                Enum.map(result, fn m -> Query.Helper.replace_keys(m, tuple) end)
              end
            else
              # if map contain only list
              IO.inspect(select)
              fields =
                Enum.reduce(
                  select,
                  [],
                  fn {key, value}, fields ->
                    if key == "$fields" do
                      fields ++ Enum.map(value, &String.to_existing_atom/1)
                    else
                      # if map contain asso_table and fields
                      relation_name = String.to_existing_atom(key)
                      assoc_fields = value
                      Query.Helper.associations(model, relation_name, fields, assoc_fields)
                    end
                  end
                )
              IO.inspect(fields)
              from(q in queryable, select: map(q, ^Enum.uniq(fields)))
            end
        end
      end
    end
  end
end
