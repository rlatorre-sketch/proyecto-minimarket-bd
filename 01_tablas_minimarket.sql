-- =========================================================================
-- ARCHIVO: 01_tablas_minimarket.sql (Versión 2.0 - Evaluación Parcial 2)
-- PROYECTO: Sistema de Gestión y Auditoría - Minimarket
-- =========================================================================

SET SERVEROUTPUT ON;

-- 1. LIMPIEZA PREVIA (Borra tablas anteriores si existen para recrearlas limpias)
BEGIN
    FOR t IN (SELECT table_name FROM user_tables 
              WHERE table_name IN ('INVENTARIO_MINIMARKET', 'CATEGORIAS_MINIMARKET', 
                                   'ALERTAS_REPOSICION', 'BITACORA_AUDITORIA')) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS';
    END LOOP;
END;
/

-- 2. CREACIÓN DE TABLAS DEL MODELO DE NEGOCIO

-- Tabla de Pasillos / Categorías
CREATE TABLE categorias_minimarket (
    id_categoria NUMBER PRIMARY KEY,
    nombre_categoria VARCHAR2(50) NOT NULL,
    pasillo VARCHAR2(20) NOT NULL
);

-- Tabla Principal de Inventario (Con costos y precios de venta en peso chileno)
CREATE TABLE inventario_minimarket (
    id_producto NUMBER PRIMARY KEY,
    id_categoria NUMBER NOT NULL,
    nombre VARCHAR2(100) NOT NULL,
    stock NUMBER NOT NULL,
    stock_minimo NUMBER DEFAULT 15 NOT NULL,
    precio_costo NUMBER(10) NOT NULL,
    precio_venta NUMBER(10) NOT NULL,
    CONSTRAINT fk_categoria_inv FOREIGN KEY (id_categoria) 
        REFERENCES categorias_minimarket(id_categoria)
);

-- Tabla para Procesamiento Masivo de Alertas (Usada por Procedimientos)
CREATE TABLE alertas_reposicion (
    id_alerta NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_producto NUMBER NOT NULL,
    nombre_producto VARCHAR2(100) NOT NULL,
    stock_detectado NUMBER NOT NULL,
    cantidad_sugerida NUMBER NOT NULL,
    inversion_estimada NUMBER(12) NOT NULL,
    nivel_urgencia VARCHAR2(30) NOT NULL,
    fecha_registro DATE DEFAULT SYSDATE
);

-- Tabla de Auditoría de Seguridad (Usada por Triggers de Fila y Sentencia)
CREATE TABLE bitacora_auditoria (
    id_bitacora NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tabla_afectada VARCHAR2(50) NOT NULL,
    tipo_operacion VARCHAR2(20) NOT NULL,
    nivel_trigger VARCHAR2(20) NOT NULL, -- 'FILA' o 'SENTENCIA'
    detalle_evento VARCHAR2(300) NOT NULL,
    usuario_bd VARCHAR2(50) DEFAULT USER,
    fecha_evento TIMESTAMP DEFAULT SYSTIMESTAMP
);

-- 3. INSERCIÓN DE LAS 10 CATEGORÍAS DEL MINIMARKET
INSERT INTO categorias_minimarket VALUES (1, 'Abarrotes y Despensa', 'Pasillo 1');
INSERT INTO categorias_minimarket VALUES (2, 'Bebidas y Jugos', 'Pasillo 2');
INSERT INTO categorias_minimarket VALUES (3, 'Lácteos y Refrigerados', 'Pasillo 3');
INSERT INTO categorias_minimarket VALUES (4, 'Panadería y Pastelería', 'Pasillo 4');
INSERT INTO categorias_minimarket VALUES (5, 'Snacks y Confites', 'Pasillo 5');
INSERT INTO categorias_minimarket VALUES (6, 'Aseo y Limpieza Hogar', 'Pasillo 6');
INSERT INTO categorias_minimarket VALUES (7, 'Higiene y Perfumería', 'Pasillo 7');
INSERT INTO categorias_minimarket VALUES (8, 'Fiambrería y Quesos', 'Pasillo 8');
INSERT INTO categorias_minimarket VALUES (9, 'Congelados y Helados', 'Pasillo 9');
INSERT INTO categorias_minimarket VALUES (10, 'Mascotas y Otros', 'Pasillo 10');

-- 4. CARGA AUTOMATIZADA DE 100 PRODUCTOS REALISTAS
DECLARE
    TYPE t_nombres IS VARRAY(10) OF VARCHAR2(60);
    TYPE t_formatos IS VARRAY(10) OF VARCHAR2(40);
    
    -- Productos base por cada una de las 10 categorías
    v_productos_base t_nombres := t_nombres(
        'Arroz Grado 1', 'Bebida Gaseosa', 'Leche Entera', 'Pan de Molde', 'Papas Fritas',
        'Detergente Líquido', 'Shampoo Familiar', 'Queso Gauda Laminado', 'Helado Casata', 'Alimento Perro Adulto'
    );
    
    -- 10 Variantes/Marcas para generar 10 x 10 = 100 productos únicos
    v_variantes t_formatos := t_formatos(
        'Formato Económico 500g', 'Selección Especial 1Kg', 'Pack Ahorro Familiar', 'Edición Clásica', 'Versión Light/Zero',
        'Formato Individual', 'Marca Propia Minimarket', 'Importado Premium', 'Envase Recargable', 'Promoción Mayorista'
    );
    
    v_id_prod NUMBER := 100;
    v_stock NUMBER;
    v_costo NUMBER;
    v_venta NUMBER;
BEGIN
    FOR cat IN 1..10 LOOP
        FOR var IN 1..10 LOOP
            v_id_prod := v_id_prod + 1;
            
            -- Asignamos stocks estratégicos: algunos en 0 (quiebre), otros bajos (<=15) y otros altos
            IF MOD(v_id_prod, 12) = 0 THEN
                v_stock := 0; -- Quiebre total (Alerta Roja)
            ELSIF MOD(v_id_prod, 4) = 0 THEN
                v_stock := TRUNC(DBMS_RANDOM.VALUE(2, 15)); -- Stock crítico (Alerta Amarilla)
            ELSE
                v_stock := TRUNC(DBMS_RANDOM.VALUE(16, 90)); -- Stock saludable
            END IF;
            
            -- Precios realistas en pesos chilenos (Costo entre $800 y $4.500, Venta con margen del 40%)
            v_costo := ROUND(DBMS_RANDOM.VALUE(8, 45)) * 100;
            v_venta := ROUND((v_costo * 1.4) / 100) * 100;
            
            INSERT INTO inventario_minimarket (
                id_producto, id_categoria, nombre, stock, stock_minimo, precio_costo, precio_venta
            ) VALUES (
                v_id_prod, 
                cat, 
                v_productos_base(cat) || ' - ' || v_variantes(var), 
                v_stock, 
                15, 
                v_costo, 
                v_venta
            );
        END LOOP;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('========================================================');
    DBMS_OUTPUT.PUT_LINE('¡CARGA EXITOSA: 10 Categorías y 100 Productos creados!');
    DBMS_OUTPUT.PUT_LINE('========================================================');
END;
/

-- 5. VERIFICACIÓN RÁPIDA
SELECT COUNT(*) AS TOTAL_PRODUCTOS_CARGADOS FROM inventario_minimarket;