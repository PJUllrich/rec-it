defmodule Mix.Tasks.UploadData do
  @moduledoc "Uploads all images from the data/valid path to S3."
  use Mix.Task

  require Logger

  @preferred_cli_env :dev

  @default_path "./data"

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    base_path = Keyword.get(args, :path, @default_path)

    base_path
    |> Recit.Files.load_file_list()
    |> prompt(base_path)
  end

  defp prompt(file_list, base_path) do
    bucket = Recit.Storage.bucket()
    message = "Will upload #{length(file_list)} files to bucket: '#{bucket}'."

    if Mix.shell().yes?(message) do
      file_list
      |> upload_files(base_path)
      |> handle_result()
    else
      Mix.shell().info("Upload aborted.")
    end
  end

  defp upload_files(file_list, base_path) do
    # Ignore the debug messages from ExAws
    Logger.configure(level: :warning)

    Enum.reduce_while(file_list, {:ok, 0}, fn file, {:ok, count} ->
      %{"filepaths" => file_path} = file
      file = base_path |> Path.join(file_path) |> File.read!()

      case Recit.Storage.upload(file_path, file) do
        %{status_code: 200} -> {:cont, {:ok, count + 1}}
        %{body: error} -> {:halt, {:error, "Upload error for #{file_path}: #{inspect(error)}"}}
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
