# Integrantes: Alejandro Vargas Rodríguez y Juan Pablo Ríos.
defmodule Reportes do
  @moduledoc "Imprime reportes y comprobantes; no altera los cálculos."

  @doc "Imprime R1 a R8 en el orden exigido usando solo los servicios válidos."
  def mostrar(repartidores, zonas, servicios, rechazados, liquidaciones) do
    r1(rechazados)
    r2(zonas, servicios)
    r3(servicios)
    r4(liquidaciones)
    r5(repartidores, servicios)
    r6(repartidores, servicios)
    r7(liquidaciones)
    r8(repartidores, zonas, servicios)
  end

  defp titulo(texto), do: Util2.mostrar("\n========== #{texto} ==========", :mensaje)
  defp decir(texto), do: Util2.mostrar(texto, :mensaje)
  defp decimal(valor), do: Util2.decimal(valor)

  # R1 usa los rechazados; ningún otro reporte los utiliza.
  defp r1(rechazados) do
    titulo("R1 - SERVICIOS RECHAZADOS")
    if rechazados == [], do: decir("No hay servicios rechazados.")

    Enum.each(rechazados, fn rechazo ->
      IO.inspect(rechazo.servicio, label: "Servicio rechazado")
      decir("Motivo: #{rechazo.motivo}")
    end)

    cantidades = Enum.frequencies_by(rechazados, & &1.motivo)

    Enum.each(
      [
        :repartidor_desconocido,
        :zona_desconocida,
        :dia_invalido,
        :kilometros_fuera_de_rango,
        :retraso_invalido
      ],
      fn motivo ->
        cantidad =
          case cantidades[motivo] do
            nil -> 0
            valor -> valor
          end

        decir("#{motivo}: #{cantidad}")
      end
    )
  end

  # R2 conserva zonas vacías y ordena por densidad, no por kilómetros.
  defp r2(zonas, servicios) do
    titulo("R2 - ZONAS POR DENSIDAD")

    Enum.each(Liquidacion.zonas_recorridas(zonas, servicios), fn zona ->
      decir(
        "#{zona.id} - #{zona.nombre}: #{decimal(zona.kilometros)} km | Densidad: #{decimal(zona.densidad)} km/km²"
      )
    end)
  end

  # R3 evalúa la meta en cada uno de los seis días, incluidos los vacíos.
  defp r3(servicios) do
    titulo("R3 - META DIARIA")
    mapa = Liquidacion.kilometros_diarios(servicios)

    Enum.each(Liquidacion.dias(), fn dia ->
      decir(
        "Día #{dia}: #{decimal(mapa[dia])} km | Meta alcanzada: #{mapa[dia] >= Liquidacion.meta_diaria()}"
      )
    end)

    decir(
      "Meta alcanzada todos los días: #{Enum.all?(Liquidacion.dias(), &(mapa[&1] >= Liquidacion.meta_diaria()))}"
    )

    decir(
      "Meta alcanzada al menos un día: #{Enum.any?(Liquidacion.dias(), &(mapa[&1] >= Liquidacion.meta_diaria()))}"
    )
  end

  # El acumulador de reduce numera la lista sin modificar las liquidaciones.
  defp r4(liquidaciones) do
    titulo("R4 - LIQUIDACIÓN SEMANAL")
    ordenados = Investigacion.ranking(liquidaciones, campo: :neto, orden: :desc)

    Enum.reduce(ordenados, 1, fn dato, numero ->
      decir("#{numero}. #{dato.codigo} - #{dato.nombre} | #{decimal(dato.kilometros)} km")

      decir(
        "Servicios: $#{decimal(dato.valor_servicios)} | Bonificaciones: $#{decimal(dato.bonificaciones)} | Alquiler: $#{decimal(dato.alquiler)} | Neto: $#{decimal(dato.neto)}"
      )

      numero + 1
    end)
  end

  # R5 muestra todos los empatados y cuenta las veces que lideraron.
  defp r5(repartidores, servicios) do
    titulo("R5 - PRIMEROS POR DÍA")
    diarios = Liquidacion.lideres_diarios(repartidores, servicios)

    Enum.each(diarios, fn dia ->
      decir("Día #{dia.dia}:")
      if dia.lideres == [], do: decir("Sin servicios válidos; no hay primer lugar.")

      Enum.each(dia.lideres, fn lider ->
        decir("#{lider.codigo} - #{lider.nombre}: #{decimal(lider.kilometros)} km")
      end)
    end)

    decir("Primer lugar en más días:")
    ganadores = Liquidacion.primeros_mas_dias(diarios)
    if ganadores == [], do: decir("Ningún repartidor tiene días trabajados.")
    Enum.each(ganadores, &decir("#{&1.codigo} - #{&1.nombre}: #{&1.dias} días"))
  end

  # R6 elige el mínimo ponderado entre los candidatos elegibles.
  defp r6(repartidores, servicios) do
    titulo("R6 - MEJOR PUNTUALIDAD PONDERADA")
    candidatos = Liquidacion.puntualidad(repartidores, servicios)
    mejores = Liquidacion.mejores_puntualidad(candidatos)
    if mejores == [], do: decir("No hay repartidores con al menos tres servicios válidos.")

    Enum.each(mejores, fn dato ->
      decir(
        "#{dato.codigo} - #{dato.nombre}: #{decimal(dato.ponderado)} minutos ponderados | #{dato.cantidad} servicios"
      )
    end)
  end

  # No se divide entre cero cuando la empresa no tiene kilómetros válidos.
  defp r7(liquidaciones) do
    titulo("R7 - TOTAL PAGADO Y COSTO POR KILÓMETRO")
    totales = Liquidacion.totales(liquidaciones)
    decir("Total pagado: $#{decimal(totales.total)}")
    decir("Kilómetros válidos: #{decimal(totales.kilometros)}")

    if totales.kilometros > 0 do
      decir("Costo promedio pagado por kilómetro: $#{decimal(totales.promedio)}")
    else
      decir("Sin kilómetros válidos: el costo por kilómetro no se puede calcular.")
    end
  end

  # R8 requiere presencia en cada zona, sin contar los rechazados.
  defp r8(repartidores, zonas, servicios) do
    titulo("R8 - REPARTIDORES EN TODAS LAS ZONAS")
    resultado = Liquidacion.todas_las_zonas(repartidores, zonas, servicios)
    if resultado == [], do: decir("Ningún repartidor trabajó en todas las zonas.")
    Enum.each(resultado, &decir("#{&1.codigo} - #{&1.nombre}"))
  end

  @doc "Muestra días trabajados y totales del repartidor, o informa un código desconocido."
  def comprobante(codigo, liquidaciones) do
    titulo("COMPROBANTE DEL REPARTIDOR")

    case Enum.find(liquidaciones, &(&1.codigo == codigo)) do
      nil ->
        decir("No existe un repartidor con el código #{codigo}.")

      dato ->
        decir("#{dato.nombre} - #{dato.codigo}")
        if dato.detalle == [], do: decir("Sin días trabajados.")

        Enum.each(dato.detalle, fn dia ->
          decir(
            "Día #{dia.dia}: #{decimal(dia.kilometros)} km | Servicios: $#{decimal(dia.valor_servicios)} | Bonificación: $#{decimal(dia.bonificacion)}"
          )
        end)

        decir("Suma de servicios: $#{decimal(dato.valor_servicios)}")
        decir("Suma de bonificaciones: $#{decimal(dato.bonificaciones)}")
        decir("Descuento por alquiler: $#{decimal(dato.alquiler)}")
        decir("Neto a pagar: $#{decimal(dato.neto)}")
    end
  end

  @doc "Muestra ranking, combinación, tiempos reales y comparación de promedios."
  def investigacion(servicios, liquidaciones, repartidores) do
    titulo("INVESTIGACIÓN - KEYWORD LISTS, MAP.MERGE Y MEDICIONES")
    decir("Ranking por kilómetros de mayor a menor (configurado con keyword list):")

    Investigacion.ranking(liquidaciones, campo: :kilometros, orden: :desc)
    |> Enum.each(&decir("#{&1.codigo}: #{decimal(&1.kilometros)} km"))

    propio = Liquidacion.kilometros_diarios(servicios)
    aliado = Investigacion.empresa_aliada()
    IO.inspect(propio, label: "Kilómetros propios R3")
    IO.inspect(aliado, label: "Empresa aliada")
    IO.inspect(Map.merge(propio, aliado), label: "Map.merge/2 reemplaza coincidencias")
    IO.inspect(Investigacion.combinar(propio, aliado), label: "Map.merge/3 suma coincidencias")

    decir(
      "El día 7 queda en la combinación con 180 km, pero no amplía los seis días de operación propios."
    )

    medidas = Investigacion.medir(servicios)

    decir(
      "Medición de #{medidas.repeticiones} repeticiones: filtros #{medidas.filtros} microsegundos; reduce #{medidas.reduce} microsegundos."
    )

    decir(
      "Resultados de ambos métodos iguales: #{medidas.coinciden}. Los tiempos varían entre ejecuciones."
    )

    decir("Comparación de promedios para justificar R6 con los datos del grupo:")

    Liquidacion.puntualidad(repartidores, servicios)
    |> Enum.each(fn dato ->
      decir(
        "#{dato.codigo}: simple #{decimal(dato.simple)} min; ponderado #{decimal(dato.ponderado)} min"
      )
    end)
  end
end
