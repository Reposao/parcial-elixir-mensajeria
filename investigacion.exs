# Integrantes: Alejandro Vargas Rodríguez y Juan Pablo Ríos.
defmodule Investigacion do
  @moduledoc "Ranking configurable, combinación de empresas y mediciones propias."

  @doc """
  Recibe una lista de mapas y una keyword list de opciones.
  campo indica la clave que se compara; orden admite :asc o :desc.
  Por defecto usa campo: :neto y orden: :desc. Retorna una nueva lista ordenada.

  Ejemplo: Investigacion.ranking(lista, campo: :kilometros, orden: :desc).
  """
  def ranking(coleccion, opciones) do
    campo = Keyword.get(opciones, :campo, :neto)
    orden = Keyword.get(opciones, :orden, :desc)
    Enum.sort_by(coleccion, fn dato -> dato[campo] end, orden)
  end

  @doc "Mapa diario proporcionado por el enunciado, incluido el día 7."
  def empresa_aliada, do: %{1 => 580.5, 2 => 430, 3 => 510, 5 => 625, 7 => 180}

  @doc "Suma kilómetros cuando coinciden claves y conserva días de ambas empresas."
  def combinar(empresapropia, aliada) do
    Map.merge(empresapropia, aliada, fn _dia, kilometros1, kilometros2 ->
      kilometros1 + kilometros2
    end)
  end

  @doc "Alternativa de R3 con un acumulador inicial para los seis días."
  def kilometros_con_reduce(servicios) do
    inicial =
      Enum.reduce(Liquidacion.dias(), %{}, fn dia, mapa ->
        Map.update(mapa, dia, 0, fn _ -> 0 end)
      end)

    Enum.reduce(servicios, inicial, fn servicio, mapa ->
      Map.update(mapa, servicio.dia, servicio.kilometros, &(&1 + servicio.kilometros))
    end)
  end

  @doc "Mide 100 repeticiones sin imprimir dentro de los cálculos. Retorna microsegundos."
  def medir(servicios) do
    {tiempo_filtros, resultados1} =
      :timer.tc(fn ->
        for _ <- 1..100, do: Liquidacion.kilometros_diarios(servicios)
      end)

    {tiempo_reduce, resultados2} =
      :timer.tc(fn ->
        for _ <- 1..100, do: kilometros_con_reduce(servicios)
      end)

    %{
      filtros: tiempo_filtros,
      reduce: tiempo_reduce,
      repeticiones: 100,
      coinciden: resultados1 == resultados2
    }
  end
end
