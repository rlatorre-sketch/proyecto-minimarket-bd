-- =========================================================================
-- ARCHIVO: 03_objetos_plsql_ev2.sql
-- PROYECTO: Sistema de Gestión y Auditoría - Minimarket (Evaluación 2)
-- CONTENIDO: Funciones, Procedimientos, Package (Público/Privado) y Triggers
-- =========================================================================

SET SERVEROUTPUT ON;

-- =========================================================================
-- 1. FUNCIONES ALMACENADAS (CON Y SIN PARÁMETROS)
-- =========================================================================

-- 1.1 Función CON parámetros: Calcula cuánto dinero cuesta reponer un producto
-- Puede usarse tanto en sentencias SELECT masivas como dentro de otros bloques PL/SQL
CREATE OR REPLACE FUNCTION fn_calcular_inversion_reposicion (
    p_stock_actual IN NUMBER,
    p_stock_minimo IN NUMBER,
    p_precio_costo IN NUMBER
) RETURN NUMBER IS
    v_unidades_comprar NUMBER := 0;
    v_inversion_total  NUMBER := 0;
BEGIN
    -- Si el stock está bajo o igual al mínimo, compramos hasta llegar al doble del mínimo (30 uds)
    IF p_stock_actual <= p_stock_minimo THEN
        v_unidades_comprar := (p_stock_minimo * 2) - p_stock_actual;
        v_inversion_total  := v_unidades_comprar * p_precio_costo;
    END IF;
    
    RETURN v_inversion_total;
END fn_calcular_inversion_reposicion;
/

-- 1.2 Función SIN parámetros: Calcula el patrimonio total valorizado del minimarket
CREATE OR REPLACE FUNCTION fn_valorizacion_total_bodega 
RETURN NUMBER IS
    v_patrimonio_total NUMBER := 0;
BEGIN
    SELECT NVL(SUM(stock * precio_venta), 0)
    INTO v_patrimonio_total
    FROM inventario_minimarket;
    
    RETURN v_patrimonio_total;
END fn_valorizacion_total_bodega;
/

-- =========================================================================
-- 2. PROCEDIMIENTOS ALMACENADOS (CON Y SIN PARÁMETROS)
-- =========================================================================

-- 2.1 Procedimiento SIN parámetros: Procesamiento masivo de alertas de reposición
-- Barre los 100 productos, usa la función almacenada y llena la tabla alertas_reposicion
CREATE OR REPLACE PROCEDURE sp_generar_alertas_masivas IS
    CURSOR c_criticos IS
        SELECT id_producto, nombre, stock, stock_minimo, precio_costo
        FROM inventario_minimarket
        WHERE stock <= stock_minimo
        ORDER BY stock ASC;
        
    v_inversion NUMBER;
    v_urgencia  VARCHAR2(30);
    v_contador  NUMBER := 0;
BEGIN
    -- Limpiamos alertas previas para generar el reporte actualizado
    DELETE FROM alertas_reposicion;
    
    FOR r_prod IN c_criticos LOOP
        -- Llamamos a nuestra Función Almacenada CON parámetros dentro de PL/SQL
        v_inversion := fn_calcular_inversion_reposicion(
            r_prod.stock, r_prod.stock_minimo, r_prod.precio_costo
        );
        
        IF r_prod.stock = 0 THEN
            v_urgencia := 'ROJA - QUIEBRE TOTAL';
        ELSE
            v_urgencia := 'AMARILLA - STOCK CRÍTICO';
        END IF;
        
        INSERT INTO alertas_reposicion (
            id_producto, nombre_producto, stock_detectado, 
            cantidad_sugerida, inversion_estimada, nivel_urgencia
        ) VALUES (
            r_prod.id_producto, r_prod.nombre, r_prod.stock,
            (r_prod.stock_minimo * 2) - r_prod.stock, v_inversion, v_urgencia
        );
        
        v_contador := v_contador + 1;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Procedimiento masivo finalizado: ' || v_contador || ' alertas generadas.');
END sp_generar_alertas_masivas;
/

-- 2.2 Procedimiento CON parámetros: Reajuste masivo de precios por pasillo/categoría
CREATE OR REPLACE PROCEDURE sp_reajustar_precios_pasillo (
    p_id_categoria IN NUMBER,
    p_porcentaje   IN NUMBER
) IS
    v_filas_afectadas NUMBER;
BEGIN
    UPDATE inventario_minimarket
    SET precio_venta = ROUND(precio_venta * (1 + (p_porcentaje / 100)))
    WHERE id_categoria = p_id_categoria;
    
    v_filas_afectadas := SQL%ROWCOUNT;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Se actualizaron ' || v_filas_afectadas || 
                         ' productos de la categoría ' || p_id_categoria || 
                         ' en un ' || p_porcentaje || '%.');
END sp_reajustar_precios_pasillo;
/

-- =========================================================================
-- 3. PACKAGE CON ELEMENTOS PÚBLICOS Y PRIVADOS
-- =========================================================================

-- 3.1 ESPECIFICACIÓN DEL PACKAGE (Parte Pública: visible para otros procesos/apps)
CREATE OR REPLACE PACKAGE pkg_gestion_minimarket IS
    -- Constante pública
    c_stock_seguridad CONSTANT NUMBER := 30;
    
    -- Función pública: Obtiene el margen de ganancia de un producto
    FUNCTION fn_obtener_margen_unitario(p_id_prod IN NUMBER) RETURN NUMBER;
    
    -- Procedimiento público: Aplica descuento validando con función privada que no haya pérdida
    PROCEDURE sp_aplicar_oferta_pasillo(p_id_cat IN NUMBER, p_descuento_pct IN NUMBER);
END pkg_gestion_minimarket;
/

-- 3.2 CUERPO DEL PACKAGE (Parte Privada + Implementación)
CREATE OR REPLACE PACKAGE BODY pkg_gestion_minimarket IS

    -- FUNCIÓN PRIVADA (Oculta al exterior, solo existe dentro del Body del Package)
    -- Verifica que el nuevo precio con descuento NUNCA sea menor al precio de costo
    FUNCTION fn_es_descuento_rentable_priv(
        p_costo        IN NUMBER, 
        p_nuevo_precio IN NUMBER
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN (p_nuevo_precio > p_costo);
    END fn_es_descuento_rentable_priv;

    -- Implementación de Función Pública
    FUNCTION fn_obtener_margen_unitario(p_id_prod IN NUMBER) RETURN NUMBER IS
        v_costo NUMBER;
        v_venta NUMBER;
    BEGIN
        SELECT precio_costo, precio_venta 
        INTO v_costo, v_venta
        FROM inventario_minimarket
        WHERE id_producto = p_id_prod;
        
        RETURN (v_venta - v_costo);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
    END fn_obtener_margen_unitario;

    -- Implementación de Procedimiento Público (Usa la función privada internamente)
    PROCEDURE sp_aplicar_oferta_pasillo(p_id_cat IN NUMBER, p_descuento_pct IN NUMBER) IS
        CURSOR c_prod_cat IS
            SELECT id_producto, nombre, precio_costo, precio_venta
            FROM inventario_minimarket
            WHERE id_categoria = p_id_cat;
            
        v_nuevo_precio NUMBER;
        v_aplicados    NUMBER := 0;
        v_bloqueados   NUMBER := 0;
    BEGIN
        FOR r IN c_prod_cat LOOP
            v_nuevo_precio := ROUND(r.precio_venta * (1 - (p_descuento_pct / 100)));
            
            -- Uso del constructor/función PRIVADA para proteger el negocio
            IF fn_es_descuento_rentable_priv(r.precio_costo, v_nuevo_precio) THEN
                UPDATE inventario_minimarket
                SET precio_venta = v_nuevo_precio
                WHERE id_producto = r.id_producto;
                v_aplicados := v_aplicados + 1;
            ELSE
                v_bloqueados := v_bloqueados + 1;
            END IF;
        END LOOP;
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Oferta procesada -> Aplicados: ' || v_aplicados || 
                             ' | Bloqueados por pérdida (Función Privada): ' || v_bloqueados);
    END sp_aplicar_oferta_pasillo;

BEGIN
    -- Bloque constructor de inicialización del Package (se ejecuta al cargarse en memoria)
    DBMS_OUTPUT.PUT_LINE('>> Package PKG_GESTION_MINIMARKET inicializado en memoria <<');
END pkg_gestion_minimarket;
/

-- =========================================================================
-- 4. TRIGGERS (A NIVEL DE FILA Y A NIVEL DE SENTENCIA)
-- =========================================================================

-- 4.1 Trigger a NIVEL DE FILA (FOR EACH ROW)
-- Valida que no exista stock negativo y audita el valor antiguo (:OLD) y nuevo (:NEW) de cada producto
CREATE OR REPLACE TRIGGER trg_auditoria_fila_inventario
BEFORE INSERT OR UPDATE OF stock, precio_venta ON inventario_minimarket
FOR EACH ROW
BEGIN
    -- Regla de negocio: Impedir stock negativo
    IF :NEW.stock < 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'ERROR CRÍTICO: No se permite registrar stock negativo en ' || :NEW.nombre);
    END IF;

    -- Si es una actualización, registramos el detalle exacto fila por fila
    IF UPDATING THEN
        INSERT INTO bitacora_auditoria (
            tabla_afectada, tipo_operacion, nivel_trigger, detalle_evento
        ) VALUES (
            'INVENTARIO_MINIMARKET', 
            'UPDATE', 
            'FILA',
            'Prod ID ' || :OLD.id_producto || ': Stock (' || :OLD.stock || '->' || :NEW.stock || 
            ') | Precio ($' || :OLD.precio_venta || '->$' || :NEW.precio_venta || ')'
        );
    END IF;
END trg_auditoria_fila_inventario;
/

-- 4.2 Trigger a NIVEL DE SENTENCIA (Sin FOR EACH ROW)
-- Se dispara UNA SOLA VEZ por cada instrucción masiva (INSERT, UPDATE o DELETE) sobre la tabla
CREATE OR REPLACE TRIGGER trg_auditoria_sentencia_inventario
AFTER INSERT OR UPDATE OR DELETE ON inventario_minimarket
DECLARE
    v_accion VARCHAR2(20);
BEGIN
    IF INSERTING THEN
        v_accion := 'INSERT MASIVO';
    ELSIF UPDATING THEN
        v_accion := 'UPDATE MASIVO';
    ELSIF DELETING THEN
        v_accion := 'DELETE MASIVO';
    END IF;

    INSERT INTO bitacora_auditoria (
        tabla_afectada, tipo_operacion, nivel_trigger, detalle_evento
    ) VALUES (
        'INVENTARIO_MINIMARKET', 
        v_accion, 
        'SENTENCIA',
        'Ejecución de sentencia global sobre la tabla de inventario por el usuario ' || USER
    );
END trg_auditoria_sentencia_inventario;
/

-- =========================================================================
-- 5. BLOQUE DE PRUEBA INTEGRAL (Para demostrar todo funcionando al Profesor)
-- =========================================================================
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== PRUEBA 1: FUNCIÓN SIN PARÁMETROS ===');
    DBMS_OUTPUT.PUT_LINE('Patrimonio total en bodega: $' || fn_valorizacion_total_bodega());

    DBMS_OUTPUT.PUT_LINE(CHR(10) || '=== PRUEBA 2: PROCEDIMIENTO SIN PARÁMETROS (MASIVO) ===');
    sp_generar_alertas_masivas();

    DBMS_OUTPUT.PUT_LINE(CHR(10) || '=== PRUEBA 3: PROCEDIMIENTO CON PARÁMETROS ===');
    sp_reajustar_precios_pasillo(1, 5); -- Sube 5% al Pasillo 1 (Dispara Triggers de Fila y Sentencia)

    DBMS_OUTPUT.PUT_LINE(CHR(10) || '=== PRUEBA 4: PACKAGE (PÚBLICO Y PRIVADO) ===');
    DBMS_OUTPUT.PUT_LINE('Margen unitario Prod 101: $' || pkg_gestion_minimarket.fn_obtener_margen_unitario(101));
    pkg_gestion_minimarket.sp_aplicar_oferta_pasillo(2, 20); -- Descuento del 20% al Pasillo 2
END;
/

-- Consultas de verificación para mostrar en la presentación:
SELECT id_producto, nombre, stock, precio_costo, 
       fn_calcular_inversion_reposicion(stock, stock_minimo, precio_costo) AS INVERSION_REQUERIDA
FROM inventario_minimarket 
WHERE stock <= stock_minimo
FETCH FIRST 10 ROWS ONLY;

SELECT * FROM alertas_reposicion FETCH FIRST 10 ROWS ONLY;
SELECT * FROM bitacora_auditoria ORDER BY id_bitacora DESC FETCH FIRST 15 ROWS ONLY;