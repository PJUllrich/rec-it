defmodule Mix.Tasks.UploadData do
  @moduledoc "Uploads all images from the data/valid path to S3."
  use Mix.Task

  require Logger

  @preferred_cli_env :dev

  @data_path "./data"

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    data_path = Keyword.get(args, :path, @data_path)

    Recit.Files.load_file_list()
    |> prompt(data_path)
  end

  defp prompt(file_list, data_path) do
    bucket = Recit.Storage.bucket()
    message = "Will upload #{length(file_list)} files to bucket: '#{bucket}'."

    if Mix.shell().yes?(message) do
      file_list
      |> upload_files(data_path)
      |> handle_result()
    else
      Mix.shell().info("Upload aborted.")
    end
  end

  defp upload_files(file_list, data_path) do
    # Ignore the debug messages from ExAws
    Logger.configure(level: :warning)

    Enum.reduce_while(file_list, {:ok, 0}, fn file, {:ok, count} ->
      %{"filepaths" => file_path} = file
      file = data_path |> Path.join(file_path) |> File.read!()

      case Recit.Storage.upload(file_path, file) do
        {:ok, %{status_code: 200}} ->
          {:cont, {:ok, count + 1}}

        {:error, {_error, %{body: error}}} ->
          {:halt, {:error, "Upload error for #{file_path}: #{inspect(error)}"}}
      end
    end)
  end

  defp handle_result({:ok, count}) do
    Mix.shell().info("Uploaded #{count} files.")
  end

  defp handle_result({:error, error}) do
    Mix.shell().error(error)
  end
end
