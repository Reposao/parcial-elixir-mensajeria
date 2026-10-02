# Integrantes: Alejandro Vargas Rodríguez y Juan Pablo Ríos.
defmodule Mensajeria do
  @moduledoc "Organiza los datos, la entrada adicional, los reportes y el comprobante."

  @doc "Coordina entrada y salida con las funciones puras de validación y cálculo."
  def main do
    repartidores = Datos.repartidores()
    zonas = Datos.zonas()
    servicios = Datos.servicios()
    {validos, rechazados} = Validacion.separar(servicios, repartidores, zonas)

    {todos_validos, todos_rechazados} =
      servicio_adicional(validos, rechazados, repartidores, zonas)

    liquidaciones = Liquidacion.liquidar(repartidores, todos_validos)
    Reportes.mostrar(repartidores, zonas, todos_validos, todos_rechazados, liquidaciones)
    codigo = Util2.ingresar("\nIngrese el código del repartidor para su comprobante: ", :texto)
    Reportes.comprobante(codigo, liquidaciones)
    Reportes.investigacion(todos_validos, liquidaciones, repartidores)
  end

  # Se hace una sola pregunta y cada resultado sigue con los reportes.
  defp servicio_adicional(validos, rechazados, repartidores, zonas) do
    texto =
      Util2.ingresar(
        "Ingrese un servicio adicional\n(repartidor;zona;dia;kilometros;retraso)\no Enter para omitir: ",
        :texto
      )

    case Validacion.convertir_entrada(texto) do
      {:ok, :omitido} ->
        Util2.mostrar("No se ingresó servicio adicional.", :mensaje)
        {validos, rechazados}

      {:error, :formato_invalido} ->
        Util2.mostrar("Servicio rechazado por formato: formato_invalido.", :mensaje)
        {validos, rechazados}

      {:ok, servicio} ->
        case Validacion.validar(servicio, repartidores, zonas) do
          {:ok, _} ->
            Util2.mostrar("Servicio adicional agregado.", :mensaje)
            {[servicio | validos], rechazados}

          {:error, motivo} ->
            Util2.mostrar("Servicio adicional rechazado: #{motivo}.", :mensaje)
            {validos, [%{servicio: servicio, motivo: motivo} | rechazados]}
        end
    end
  end
end

Mensajeria.main()
