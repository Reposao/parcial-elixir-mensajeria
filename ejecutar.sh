#!/usr/bin/env bash
cd -- "$(dirname -- "$0")" || exit 1
elixir -r datos.exs -r util2.exs -r validacion.exs -r liquidacion.exs -r investigacion.exs -r reportes.exs principal.exs
