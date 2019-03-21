defmodule EASY.SoftRepo do
  @moduledoc """
  A module that has common helper functions for controllers,
  views and so on.

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """

  @doc false
  defmacro __using__(options \\ []) do
    quote location: :keep do
      import Ecto.Query
      import Ecto.Changeset, only: [change: 2]
      import Ecto.Queryable, only: [to_query: 1]
      # options = unquote(options)

      @repo unquote(options)[:base_repo]

      def one(queryable, opts \\ []) do
        queryable = exclude_thrash(queryable)
        @repo.one(queryable)
      end

      def one!(queryable, opts \\ []) do
        queryable = exclude_thrash(queryable)
        @repo.one(queryable)
      end

      def all(queryable, opts \\ [])

      def all(queryable, opts) when length(opts) == 0 do
        queryable = exclude_thrash(queryable)
        @repo.all(queryable)
      end

      def all(queryable, opts) when length(opts) > 0 do
        case with_thrash_option?(opts) do
          true ->
            queryable = exclude_thrash(queryable, false)
            opts = Keyword.drop(opts, [:with_thrash])
            @repo.all(queryable, opts)

          _ ->
            opts = Keyword.drop(opts, [:with_thrash])
            all(queryable, opts)
        end
      end

      def get(queryable, id, opts \\ [])

      def get(queryable, id, opts) when length(opts) == 0 do
        queryable = exclude_thrash(queryable)
        @repo.get(queryable, id, opts)
      end

      def get(queryable, id, opts) when length(opts) > 0 do
        case with_thrash_option?(opts) do
          true ->
            queryable = exclude_thrash(queryable, false)
            opts = Keyword.drop(opts, [:with_thrash])
            @repo.get(queryable, id, opts)

          _ ->
            opts = Keyword.drop(opts, [:with_thrash])
            get(queryable, id, opts)
        end
      end

      def get!(queryable, id, opts \\ [])

      def get!(queryable, id, opts) when length(opts) == 0 do
        queryable = exclude_thrash(queryable)
        @repo.get!(queryable, id, opts)
      end

      def get!(queryable, id, opts) when length(opts) > 0 do
        case with_thrash_option?(opts) do
          true ->
            queryable = exclude_thrash(queryable, false)
            opts = Keyword.drop(opts, [:with_thrash])
            @repo.get!(queryable, id, opts)

          _ ->
            opts = Keyword.drop(opts, [:with_thrash])
            get!(queryable, id, opts)
        end
      end

      # def delete(struct, opts \\ [])
      # def delete(struct, opts) when length(opts) == 0 do
      #   changeset = change(struct, deleted_at: Timex.now())
      #   Repo.update(changeset)
      # end
      # def delete(struct, opts) when length(opts) > 0 do
      #   case with_force_option?(opts) do
      #     true ->
      #       opts = Keyword.drop(opts, [:force])
      #       Repo.delete(struct, opts)
      #     _ -> delete(struct)
      #   end
      # end

      def delete_record(record) do
        if Map.has_key?(record, :deleted_at) do
          if record.deleted_at do
            {:already_deleted, record}
          else
            changeset = Ecto.Changeset.change(record, deleted_at: Timex.now())
            @repo.update(changeset)
          end
        else
          @repo.delete(record)
        end
      end

      def delete_all(queryable, opts \\ [])

      def delete_all(queryable, opts) when length(opts) == 0 do
        @repo.update_all(
          queryable,
          set: [
            deleted_at: Timex.now()
          ]
        )
      end

      def delete_all(queryable, opts) when length(opts) > 0 do
        case with_force_option?(opts) do
          true ->
            opts = Keyword.drop(opts, [:force])
            @repo.delete_all(queryable, opts)

          _ ->
            delete_all(queryable)
        end
      end

      def restore(queryable, id) do
        changeset = change(get!(queryable, id), deleted_at: nil)
        update(changeset)
      end

      defp exclude_thrash(queryable, exclude \\ true) do
        case EASY.Helper.field_exists?(queryable, :deleted_at) do
          false ->
            queryable

          true ->
            cond do
              exclude ->
                from(p in queryable, where: is_nil(p.deleted_at))

              true ->
                queryable
            end
        end
      end

      defp with_thrash_option?(opts), do: Keyword.get(opts, :with_thrash)

      defp with_force_option?(opts), do: Keyword.get(opts, :force)

      # Just like dynamically delegating =D
      defdelegate config(), to: @repo

      # defdelegate get_by(queryable, clauses, opts \\ []), to: @repo
      def get_by(queryable, clauses, opts \\ [])

      def get_by(queryable, clauses, opts) when length(opts) == 0 do
        queryable = exclude_thrash(queryable)
        @repo.get_by(queryable, clauses, opts)
      end

      def get_by(queryable, clauses, opts) when length(opts) > 0 do
        case with_thrash_option?(opts) do
          true ->
            queryable = exclude_thrash(queryable, false)
            opts = Keyword.drop(opts, [:with_thrash])
            @repo.get_by(queryable, clauses, opts)

          _ ->
            opts = Keyword.drop(opts, [:with_thrash])
            get_by(queryable, clauses, opts)
        end
      end

      # defdelegate get_by!(queryable, clauses, opts \\ []), to: @repo
      def get_by!(queryable, clauses, opts \\ [])

      def get_by!(queryable, clauses, opts) when length(opts) == 0 do
        queryable = exclude_thrash(queryable)
        @repo.get_by!(queryable, clauses, opts)
      end

      def get_by!(queryable, clauses, opts) when length(opts) > 0 do
        case with_thrash_option?(opts) do
          true ->
            queryable = exclude_thrash(queryable, false)
            opts = Keyword.drop(opts, [:with_thrash])
            @repo.get_by!(queryable, clauses, opts)

          _ ->
            opts = Keyword.drop(opts, [:with_thrash])
            get_by!(queryable, clauses, opts)
        end
      end

      defdelegate in_transaction?(), to: @repo

      defdelegate insert(struct, opts \\ []), to: @repo

      defdelegate insert!(struct, opts \\ []), to: @repo

      defdelegate insert_all(schema_or_source, entries, opts \\ []), to: @repo

      defdelegate insert_or_update(changeset, opts \\ []), to: @repo

      defdelegate insert_or_update!(changeset, opts \\ []), to: @repo

      # defdelegate one(queryable, opts \\ []), to: @repo

      # defdelegate one!(queryable, opts \\ []), to: @repo

      defdelegate preload(struct_or_structs, preloads, opts \\ []), to: @repo

      defdelegate rollback(value), to: @repo

      defdelegate start_link(opts \\ []), to: @repo

      defdelegate stop(pid, timeout \\ 5000), to: @repo

      defdelegate transaction(fun_or_multi, opts \\ []), to: @repo

      defdelegate update(struct, opts \\ []), to: @repo

      defdelegate update!(struct, opts \\ []), to: @repo

      defdelegate update_all(queryable, updates, opts \\ []), to: @repo

      defdelegate delete(struct, opts \\ []), to: @repo

      defdelegate delete!(struct, opts \\ []), to: @repo

      defoverridable all: 2,
                     get: 3,
                     get!: 3,
                     delete_all: 2,
                     restore: 2
    end
  end
end
