using Pkg
Pkg.activate(@__DIR__)
Pkg.develop(path=dirname(@__DIR__)) # Add PromClient if not already added. This will update Project.toml

using Documenter, DocumenterMarkdown, PromClient

makedocs(sitename="PromClient", format = Markdown())