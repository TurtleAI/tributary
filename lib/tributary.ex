defmodule Tributary do

  def stream(repo, query, opts \\ []) do
    import Ecto.Query, only: [where: 3, limit: 3]
    import Ecto.Query.API, only: [field: 2]

    {trib_opts, repo_opts} = Keyword.split(opts, [:initial_key, :key_name, :chunk_size])

    initial_key = Keyword.get(trib_opts, :initial_key, 0)
    key_name = Keyword.get(trib_opts, :key_name, :id)
    chunk_size = Keyword.get(trib_opts, :chunk_size, 500)

    Stream.resource(fn -> {query, initial_key} end,
      fn {query, last_seen_key} ->
        results = query
          |> Ecto.Query.where([r], field(r, ^key_name) > ^last_seen_key)
          |> Ecto.Query.limit(^chunk_size)
          |> repo.all(repo_opts)

        case List.last(results) do
          %{^key_name => last_key} ->
            {results, {query, last_key}}
          nil ->
            {:halt, {query, last_seen_key}}
        end
      end,
      fn _ -> [] end)
  end

end
