SET SERVEROUTPUT ON;

DECLARE
    -- Tipos de datos compuestos (RECORD y VARRAY)
    -- Estructuramos los datos de los productos que necesitan reposición urgente
    TYPE t_info_producto IS RECORD (
        nombre_producto VARCHAR2(100),
        stock_actual NUMBER
    );
    -- VARRAY en memoria RAM para guardar el Top 20 de alertas críticas
    TYPE t_arreglo_alertas IS VARRAY(20) OF t_info_producto;
    v_alertas t_arreglo_alertas := t_arreglo_alertas();
    
    --  Cursor explícito sin parámetros (Cursor principal)
    -- Recorre los pasillos/categorías del minimarket
    CURSOR c_categorias IS 
        SELECT id_categoria, nombre_categoria FROM categorias_minimarket;
    
    -- Cursor explícito complejo con parámetros (Sub-cursor)
    -- Busca productos de una categoría específica que estén bajo el stock mínimo
    CURSOR c_productos (p_id_cat NUMBER, p_stock_min NUMBER) IS 
        SELECT nombre, stock 
        FROM inventario_minimarket 
        WHERE id_categoria = p_id_cat AND stock <= p_stock_min;
        
    --  Excepciones
    e_quiebre_stock EXCEPTION; -- Excepción definida por el usuario
    v_idx NUMBER := 1;

BEGIN
    -- Inicializamos el espacio en el VARRAY
    v_alertas.EXTEND(20);
    
    --  Loop principal (Iterando por categorías)
    FOR v_cat IN c_categorias LOOP
        DBMS_OUTPUT.PUT_LINE('--- Revisando Pasillo: ' || v_cat.nombre_categoria || ' ---');
        
        -- Loop anidado (Iterando por productos de esa categoría, buscando stock <= 15)
        FOR v_prod IN c_productos(v_cat.id_categoria, 15) LOOP
            
            -- Guardamos los datos en el VARRAY para evitar consultas repetitivas a la BD
            IF v_idx <= 20 THEN
                v_alertas(v_idx).nombre_producto := v_prod.nombre;
                v_alertas(v_idx).stock_actual := v_prod.stock;
                v_idx := v_idx + 1;
            END IF;

            -- Bloque de control de errores
            BEGIN
                -- Validamos con la excepción del usuario si el stock es cero
                IF v_prod.stock = 0 THEN
                    RAISE e_quiebre_stock;
                END IF;
                
                DBMS_OUTPUT.PUT_LINE('Alerta amarilla: Quedan ' || v_prod.stock || ' de ' || v_prod.nombre);
                
            EXCEPTION
                -- Control de excepción de usuario (Quiebre total)
                WHEN e_quiebre_stock THEN
                    DBMS_OUTPUT.PUT_LINE('ALERTA ROJA: ' || v_prod.nombre || ' agotado. Pérdida de ventas inminente.');
                -- Control de excepción de Oracle[cite: 1]
                WHEN ZERO_DIVIDE THEN
                    DBMS_OUTPUT.PUT_LINE('Error de cálculo interno en el sistema.');
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
            END;
        END LOOP;
    END LOOP;
END;
