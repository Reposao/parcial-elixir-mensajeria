# Integrantes: Alejandro Vargas Rodríguez y Juan Pablo Ríos.
defmodule Liquidacion do
  @moduledoc "Cálculos puros de los servicios y de la liquidación semanal."
  @tarifa 2500
  @dias 6
  @meta_diaria 500
  @km_bonificacion 80
  @bonificacion 15000
  @alquiler 10000

  @doc "Rango de días de operación, del 1 al 6."
  def dias, do: 1..@dias
  @doc "Meta empresarial en kilómetros por día."
  def meta_diaria, do: @meta_diaria

  @doc "Valor con ajuste de puntualidad; los límites 0, 10 y 30 son inclusivos."
  def valor_servicio(servicio) do
    factor =
      cond do
        servicio.retraso <= 0 -> 1.08
        servicio.retraso <= 10 -> 1.0
        servicio.retraso <= 30 -> 0.90
        true -> 0.75
      end

    servicio.kilometros * @tarifa * factor
  end

  @doc "Suma los kilómetros de los servicios válidos recibidos."
  def sumar_kilometros(servicios), do: Enum.sum(Enum.map(servicios, & &1.kilometros))

  @doc "Incluye los seis días aunque no tengan servicios."
  def kilometros_diarios(servicios) do
    Enum.reduce(dias(), %{}, fn dia, acumulador ->
      km = servicios |> Enum.filter(&(&1.dia == dia)) |> sumar_kilometros()
      Map.update(acumulador, dia, km, fn _ -> km end)
    end)
  end

  @doc """
  Recibe un repartidor y la lista de servicios válidos.
  Retorna mapas diarios con kilómetros, valor de servicios, bonificación y alquiler.
  Solo incluye los días con servicios, para reutilizar el detalle en el comprobante.
  """
  def detalle_dias(repartidor, servicios) do
    propios = Enum.filter(servicios, &(&1.repartidor == repartidor.codigo))

    for dia <- dias(),
        del_dia = Enum.filter(propios, &(&1.dia == dia)),
        length(del_dia) > 0 do
      km = sumar_kilometros(del_dia)
      valor = Enum.sum(Enum.map(del_dia, &valor_servicio/1))
      bono = if km >= @km_bonificacion, do: @bonificacion, else: 0
      alquiler = if repartidor.bicicleta, do: @alquiler, else: 0
      %{dia: dia, kilometros: km, valor_servicios: valor, bonificacion: bono, alquiler: alquiler}
    end
  end

  @doc "Incluye todos los repartidores, aun los que no trabajaron."
  def liquidar(repartidores, servicios) do
    Enum.map(repartidores, fn repartidor ->
      detalle = detalle_dias(repartidor, servicios)
      km = Enum.sum(Enum.map(detalle, & &1.kilometros))
      valor = Enum.sum(Enum.map(detalle, & &1.valor_servicios))
      bonos = Enum.sum(Enum.map(detalle, & &1.bonificacion))
      alquiler = Enum.sum(Enum.map(detalle, & &1.alquiler))

      %{
        codigo: repartidor.codigo,
        nombre: repartidor.nombre,
        kilometros: km,
        valor_servicios: valor,
        bonificaciones: bonos,
        alquiler: alquiler,
        neto: valor + bonos - alquiler,
        detalle: detalle
      }
    end)
  end

  @doc "Incluye todas las zonas y ordena por kilómetros divididos entre área."
  def zonas_recorridas(zonas, servicios) do
    Enum.map(zonas, fn zona ->
      km = servicios |> Enum.filter(&(&1.zona == zona.id)) |> sumar_kilometros()
      %{id: zona.id, nombre: zona.nombre, kilometros: km, densidad: km / zona.area}
    end)
    |> Enum.sort_by(& &1.densidad, :desc)
  end

  @doc "Si un día no hay actividad, no se asigna primer lugar."
  def lideres_diarios(repartidores, servicios) do
    Enum.map(dias(), fn dia ->
      del_dia = Enum.filter(servicios, &(&1.dia == dia))

      totales =
        Enum.map(repartidores, fn repartidor ->
          km = del_dia |> Enum.filter(&(&1.repartidor == repartidor.codigo)) |> sumar_kilometros()
          %{codigo: repartidor.codigo, nombre: repartidor.nombre, kilometros: km}
        end)

      maximo =
        Enum.reduce(totales, 0, fn dato, mayor ->
          if dato.kilometros > mayor, do: dato.kilometros, else: mayor
        end)

      lideres = Enum.filter(totales, &(&1.kilometros == maximo and maximo > 0))
      %{dia: dia, kilometros: maximo, lideres: lideres}
    end)
  end

  @doc "Cuenta primeros lugares, incluidos empates; retorna todos los máximos."
  def primeros_mas_dias(lideres_diarios) do
    primeros = for dia <- lideres_diarios, lider <- dia.lideres, do: lider
    frecuencias = Enum.frequencies_by(primeros, & &1.codigo)

    candidatos =
      primeros
      |> Enum.map(&{&1.codigo, &1.nombre})
      |> Enum.uniq()
      |> Enum.map(fn {codigo, nombre} ->
        %{codigo: codigo, nombre: nombre, dias: frecuencias[codigo]}
      end)

    maximo =
      Enum.reduce(candidatos, 0, fn dato, mayor ->
        if dato.dias > mayor, do: dato.dias, else: mayor
      end)

    Enum.filter(candidatos, &(&1.dias == maximo))
  end

  @doc """
  Retorna promedios de los repartidores con tres o más servicios válidos en la semana.
  Ponderado = suma(retraso * kilómetros) / suma(kilómetros).
  Simple = suma(retrasos) / cantidad de servicios.
  Un retraso negativo representa una entrega anticipada, no un dato inválido.
  """
  def puntualidad(repartidores, servicios) do
    for repartidor <- repartidores,
        propios = Enum.filter(servicios, &(&1.repartidor == repartidor.codigo)),
        length(propios) >= 3 do
      km = sumar_kilometros(propios)
      ponderado = Enum.sum(Enum.map(propios, &(&1.retraso * &1.kilometros))) / km
      simple = Enum.sum(Enum.map(propios, & &1.retraso)) / length(propios)

      %{
        codigo: repartidor.codigo,
        nombre: repartidor.nombre,
        cantidad: length(propios),
        ponderado: ponderado,
        simple: simple
      }
    end
  end

  @doc "Retorna todos los empatados con menor retraso ponderado, o lista vacía."
  def mejores_puntualidad([]), do: []

  def mejores_puntualidad(puntualidades) do
    menor = Enum.min_by(puntualidades, & &1.ponderado).ponderado
    Enum.filter(puntualidades, &(&1.ponderado == menor))
  end

  @doc "Suma netos y calcula costo por kilómetro; retorna cero como promedio si no hay km."
  def totales(liquidaciones) do
    total = Enum.sum(Enum.map(liquidaciones, & &1.neto))
    km = Enum.sum(Enum.map(liquidaciones, & &1.kilometros))
    promedio = if km > 0, do: total / km, else: 0
    %{total: total, kilometros: km, promedio: promedio}
  end

  @doc "Selecciona repartidores con al menos un servicio válido en cada zona."
  def todas_las_zonas(repartidores, zonas, servicios) do
    Enum.filter(repartidores, fn repartidor ->
      propios = Enum.filter(servicios, &(&1.repartidor == repartidor.codigo))
      Enum.all?(zonas, fn zona -> Enum.any?(propios, &(&1.zona == zona.id)) end)
    end)
  end
end
