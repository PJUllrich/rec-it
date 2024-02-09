defmodule Recit.Storage do
  def upload(filepath, content) do
    bucket()
    |> ExAws.S3.put_object(filepath, content)
    |> ExAws.request!()
  end

  def download(filepath) do
    bucket()
    |> ExAws.S3.get_object(filepath)
    |> ExAws.request!()
  end

  def bucket(), do: Application.get_env(:ex_aws, :s3)[:bucket]
end
