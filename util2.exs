# Integrantes: Alejandro Vargas Rodríguez y Juan Pablo Ríos.

defmodule Util2 do
  @moduledoc """
  Entrada y salida de consola, sin reintentos recursivos.
  """

  @doc "Muestra texto en consola o en la salida de errores."
  def mostrar(mensaje, :mensaje), do: IO.puts(mensaje)
  def mostrar(mensaje, :error), do: IO.puts(:standard_error, mensaje)

  @doc """
  Lee una sola entrada.
  Enter o fin de entrada retornan una cadena vacía.
  """
  def ingresar(pregunta, :texto) do
    case IO.gets(pregunta) do
      :eof -> ""
      {:error, _} -> ""
      texto -> String.trim(texto)
    end
  end

  @doc """
  Formatea a dos decimales para mostrar.
  No redondea los cálculos del programa.
  """
  def decimal(numero) do
    :erlang.float_to_binary(numero * 1.0, decimals: 2)
  end
end
