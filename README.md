# 🛒 Sistema de Gestión de Inventario - Minimarket

Proyecto de automatización y control de stock desarrollado para la asignatura Taller de Base de Datos (BDY1103).

## 🎯 Objetivo del Proyecto
Implementar una solución eficiente en PL/SQL que procese grandes volúmenes de datos de inventario. El sistema identifica quiebres de stock en tiempo real y genera alertas preventivas para evitar la pérdida de ventas en un minimarket de alto flujo.

## 🛠️ Tecnologías y Estructuras Utilizadas
* **Lenguaje:** Oracle PL/SQL
* **Estructuras en Memoria:** Tipos de datos compuestos (`RECORD` y `VARRAY`) para optimizar el rendimiento y reducir las lecturas al disco.
* **Procesamiento de Datos:** Cursores explícitos complejos con paso de parámetros y loops anidados.
* **Control de Flujo:** Manejo de excepciones predefinidas y definidas por el usuario (`e_quiebre_stock`).

## 👥 Equipo de Desarrollo
* Ignacia Coliñir
* Armin Muñoz
* Rodrigo Latorre

## 📂 Estructura de Archivos
* `01_tablas_minimarket.sql`: Script de creación del modelo de datos e inserción de registros de prueba.
* `02_bloque_plsql.sql`: Motor principal del sistema con la lógica de cursores y arreglos.
