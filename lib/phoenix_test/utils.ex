defmodule PhoenixTest.Utils do
  @moduledoc false

  def name_to_map(name, value) do
    name
    |> name_parts()
    |> Enum.reverse()
    |> Enum.reduce(value, fn
      "[]", acc ->
        List.flatten([acc])

      key, acc ->
        %{key => acc}
    end)
  end

  # TODO test
  def delete_from_map(map, name, value) do
    case Enum.reverse(name_parts(name)) do
      ["[]" | path] ->
        update_in(map, Enum.reverse(path), fn list -> list -- [value] end)

      _ ->
        map
    end
  end

  defp name_parts(name) do
    parts = Regex.scan(~r/[\w\?|-]+|\[\]/, name)

    List.flatten(parts)
  end

  def present?(term), do: !blank?(term)
  def blank?(term), do: term == nil || term == ""

  def stringify_keys_and_values(map) do
    Map.new(map, fn {k, v} -> {to_string(k), to_string(v)} end)
  end

  def deep_merge(original, override) do
    DeepMerge.deep_merge(original, override, &list_concatenator_for_deep_merge/3)
  end

  defp list_concatenator_for_deep_merge(_key, original, override) when is_list(original) and is_list(override) do
    original = original -- [""]
    diff = override -- original
    original ++ diff
  end

  defp list_concatenator_for_deep_merge(_key, _original, _override) do
    DeepMerge.continue_deep_merge()
  end
end
