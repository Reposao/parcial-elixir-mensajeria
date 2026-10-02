# Integrantes: Alejandro Vargas Rodríguez y Juan Pablo Ríos.
defmodule Validacion do
  @moduledoc "Valida servicios en el orden exigido y convierte la entrada adicional."
  @dias 6
  @maximo_kilometros 45
  @minimo_retraso -30
  @maximo_retraso 180

  @doc """
  Recibe un mapa de servicio y las listas de repartidores y zonas.
  Devuelve {:ok, servicio} o {:error, motivo}, sin continuar después del primer error.
  El orden es repartidor, zona, día, kilómetros y retraso.
  """
  def validar(servicio, repartidores, zonas) do
    with {:ok, _} <- validar_repartidor(servicio.repartidor, repartidores),
         {:ok, _} <- validar_zona(servicio.zona, zonas),
         {:ok, _} <- validar_dia(servicio.dia),
         {:ok, _} <- validar_kilometros(servicio.kilometros),
         {:ok, _} <- validar_retraso(servicio.retraso) do
      {:ok, servicio}
    end
  end

  # Las búsquedas retornan nil cuando no existe el código o la zona.
  defp validar_repartidor(codigo, repartidores) do
    case Enum.find(repartidores, &(&1.codigo == codigo)) do
      nil -> {:error, :repartidor_desconocido}
      repartidor -> {:ok, repartidor}
    end
  end

  defp validar_zona(id, zonas) do
    case Enum.find(zonas, &(&1.id == id)) do
      nil -> {:error, :zona_desconocida}
      zona -> {:ok, zona}
    end
  end

  # Primero se verifica el tipo; después se comparan los límites inclusivos.
  defp validar_dia(dia) when is_integer(dia) and dia >= 1 and dia <= @dias,
    do: {:ok, dia}

  defp validar_dia(_), do: {:error, :dia_invalido}

  defp validar_kilometros(km) when is_number(km) and km > 0 and km <= @maximo_kilometros,
    do: {:ok, km}

  defp validar_kilometros(_), do: {:error, :kilometros_fuera_de_rango}

  defp validar_retraso(retraso)
       when is_number(retraso) and retraso >= @minimo_retraso and retraso <= @maximo_retraso,
       do: {:ok, retraso}

  defp validar_retraso(_), do: {:error, :retraso_invalido}

  @doc "Separa válidos y rechazados, conservando cada registro rechazado."
  def separar(servicios, repartidores, zonas) do
    resultados =
      Enum.map(servicios, fn servicio ->
        case validar(servicio, repartidores, zonas) do
          {:ok, valido} -> {:ok, valido}
          {:error, motivo} -> {:error, %{servicio: servicio, motivo: motivo}}
        end
      end)

    validos = for {:ok, servicio} <- resultados, do: servicio
    rechazados = for {:error, rechazo} <- resultados, do: rechazo
    {validos, rechazados}
  end

  @doc """
  Convierte una cadena repartidor;zona;dia;kilometros;retraso.
  Retorna {:ok, servicio}, {:ok, :omitido} o {:error, :formato_invalido}.
  Convertir un número no significa que cumpla los rangos: validar/3 los revisa después.
  """
  def convertir_entrada(""), do: {:ok, :omitido}

  def convertir_entrada(texto) do
    campos = String.split(texto, ";") |> Enum.map(&String.trim/1)

    case campos do
      [repartidor, zona, dia, kilometros, retraso] ->
        with {:ok, numero_dia} <- convertir_entero(dia),
             {:ok, numero_km} <- convertir_numero(kilometros),
             {:ok, numero_retraso} <- convertir_numero(retraso) do
          {:ok,
           %{
             repartidor: repartidor,
             zona: zona,
             dia: numero_dia,
             kilometros: numero_km,
             retraso: numero_retraso
           }}
        end

      _ ->
        {:error, :formato_invalido}
    end
  end

  # Solo se acepta una conversión completa: no puede quedar texto sobrante.
  defp convertir_entero(texto) do
    case Integer.parse(texto) do
      {valor, ""} -> {:ok, valor}
      _ -> {:error, :formato_invalido}
    end
  end

  # Los kilómetros y retrasos admiten enteros y decimales.
  defp convertir_numero(texto) do
    case Integer.parse(texto) do
      {valor, ""} ->
        {:ok, valor}

      _ ->
        case Float.parse(texto) do
          {valor, ""} -> {:ok, valor}
          _ -> {:error, :formato_invalido}
        end
    end
  end
end
