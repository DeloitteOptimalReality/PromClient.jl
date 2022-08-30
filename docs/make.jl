using Pkg
Pkg.activate(@__DIR__)
Pkg.develop(path=dirname(@__DIR__))

using Documenter, DocumenterMarkdown, PromClient

makedocs(sitename="PromClient", format = Markdown())