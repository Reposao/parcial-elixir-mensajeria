# Parcial de Elixir: empresa de mensajería

## Integrantes
- Alejandro Vargas Rodríguez — Reposao
- Juan Pablo Ríos — Juanpa0031

## Objetivo
Calcular la liquidación semanal de los repartidores y generar
los ocho reportes exigidos en el parcial.

## Uso de inteligencia artificial

Utilizamos ChatGPT como apoyo para resolver dudas de Elixir, generar una propuesta inicial de código y orientar las pruebas y la documentación. Durante la integración revisamos los módulos y comprobamos sus resultados. La responsabilidad de comprender, explicar y modificar la solución corresponde a ambos integrantes.

## Restricciones
Sin recursividad, structs propios, lectura o escritura con File,
procesos, proyectos Mix, librerías externas ni try/rescue.

## Requisitos
Tener Elixir instalado y disponible en la terminal.
No se necesita Mix ni librerías externas.

## Ejecutar en Windows
Abrir la carpeta del proyecto en Visual Studio Code.
En la terminal de PowerShell ejecutar:

```powershell
.\ejecutar.bat
```

## Ejecutar en Linux o macOS

```bash
bash ejecutar.sh
```

## Uso
1. Ingresar un servicio adicional, por ejemplo:
   M03;Z2;4;22.5;-3
   O pulsar Enter para omitirlo.
2. Consultar los reportes R1 a R8.
3. Ingresar el código de un repartidor, como M03,
   para mostrar su comprobante.
4. Consultar la investigación y las mediciones.

Los decimales se escriben con punto.
Las entradas inválidas se informan sin detener el programa.
Los tiempos medidos varían entre ejecuciones.