defmodule Recit.Files do
  @default_path "./data"
  @max_image_count 5

  def load_file_list(base_path \\ @default_path) do
    base_path
    |> Path.join("/valid-sports.csv")
    |> File.stream!()
    |> CSV.decode!(headers: true, separator: ?;)
    |> Enum.to_list()
  end

  def get_random_categories(file_list, count) do
    all_categories = get_all_categories(file_list)
    Enum.take_random(all_categories, count)
  end

  def get_random_image_paths_for_category(file_list, category, count)
      when count <= @max_image_count do
    file_list
    |> get_all_images_for_category(category)
    |> Enum.take_random(count)
    |> Enum.map(fn %{"filepaths" => path} -> path end)
  end

  def get_all_categories(file_list) do
    file_list
    |> Enum.reduce(%{}, fn %{"labels" => category}, acc -> Map.put(acc, category, 1) end)
    |> Map.keys()
  end

  def get_all_images_for_category(file_list, category) do
    Enum.filter(file_list, fn %{"labels" => file_category} -> file_category == category end)
  end
end
