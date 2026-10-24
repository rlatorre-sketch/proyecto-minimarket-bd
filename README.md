# 🛒 Sistema de Gestión y Auditoría de Inventario - Minimarket (v2.0)

Proyecto de automatización, control financiero de stock y auditoría de seguridad desarrollado para la asignatura Taller de Base de Datos (BDY1103).

## 📚 Información Académica
- **Asignatura:** Taller de Base de Datos
- **Sigla y Sección:** BDY1103-003V
- **Docente:** Cristian Carreño
- **Evaluación Actual:** Evaluación Parcial N° 2 (Implementación de programas PL/SQL en una base de datos)

## 👥 Equipo de Desarrollo
- Rodrigo Latorre
- Armin Muñoz
- Ignacia Coliñir

## 🎯 Objetivo del Proyecto
Implementar una arquitectura de backend modular y persistente en **Oracle PL/SQL** capaz de gestionar un catálogo escalado a **100 productos distribuidos en 10 pasillos**. El sistema automatiza la valorización financiera de la bodega, genera órdenes de compra masivas ante quiebres de stock, protege el margen comercial al aplicar descuentos por pasillo y audita en tiempo real cada transacción sobre la base de datos.

## 🛠️ Tecnologías y Arquitectura PL/SQL Implementada
- **Motor de Base de Datos:** Oracle Database 21c Express Edition (XE).
- **Estructuras en Memoria y Carga Masiva:** Uso de `RECORD`, `VARRAY`, cursores explícitos con parámetros y manejo de excepciones personalizadas (`e_quiebre_stock`).
- **Funciones Almacenadas (Con y Sin Parámetros):** 
  - `fn_valorizacion_total_bodega`: Calcula el patrimonio total inmovilizado en mercadería.
  - `fn_calcular_inversion_reposicion`: Determina el capital exacto requerido para reponer productos críticos hasta su nivel óptimo.
- **Procedimientos Almacenados (Con y Sin Parámetros):** 
  - `sp_generar_alertas_masivas`: Procesa masivamente los 100 productos e inserta órdenes priorizadas (Alerta Amarilla y Roja) en la tabla `ALERTAS_REPOSICION`.
  - `sp_reajustar_precios_pasillo`: Ejecuta actualizaciones masivas de precios por categoría informando filas afectadas mediante `SQL%ROWCOUNT`.
- **Packages (Público y Privado):** 
  - `pkg_gestion_minimarket`: Encapsula la lógica comercial exponiendo métodos públicos e implementando la función privada `fn_es_descuento_rentable_priv` en el `PACKAGE BODY` para bloquear ofertas que dejen precios bajo el costo.
- **Triggers de Base de Datos (Fila y Sentencia):** 
  - `trg_auditoria_fila_inventario` (`FOR EACH ROW`): Impide el registro de stock negativo (`RAISE_APPLICATION_ERROR`) y audita valores antiguos (`:OLD`) vs. nuevos (`:NEW`).
  - `trg_auditoria_sentencia_inventario`: Registra auditoría global en `BITACORA_AUDITORIA` por cada operación DML masiva indicando usuario y marca de tiempo.

## 📂 Estructura de Archivos del Repositorio
- `01_tablas_minimarket.sql`: Creación del modelo relacional de 4 tablas (`CATEGORIAS_MINIMARKET`, `INVENTARIO_MINIMARKET`, `ALERTAS_REPOSICION`, `BITACORA_AUDITORIA`) y rutina automatizada de carga de 100 productos.
- `02_bloque_plsql.sql`: Bloque anónimo fundacional de diagnóstico en memoria (Evaluación Parcial 1).
- `03_objetos_plsql_ev2.sql`: Script integral con Funciones, Procedimientos, Package, Triggers y bloque de pruebas de ejecución (Evaluación Parcial 2).
