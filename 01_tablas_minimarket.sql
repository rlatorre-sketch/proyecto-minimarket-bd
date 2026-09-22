-- 1. Crear las tablas
CREATE TABLE categorias_minimarket (
    id_categoria NUMBER PRIMARY KEY,
    nombre_categoria VARCHAR2(50)
);

CREATE TABLE inventario_minimarket (
    id_producto NUMBER PRIMARY KEY,
    id_categoria NUMBER,
    nombre VARCHAR2(100),
    stock NUMBER,
    CONSTRAINT fk_cat FOREIGN KEY (id_categoria) REFERENCES categorias_minimarket(id_categoria)
);

-- 2. Insertar datos de prueba
INSERT INTO categorias_minimarket VALUES (1, 'Abarrotes');
INSERT INTO categorias_minimarket VALUES (2, 'Bebidas y Licores');

INSERT INTO inventario_minimarket VALUES (100, 1, 'Arroz Tucapel 1kg', 25);
INSERT INTO inventario_minimarket VALUES (101, 1, 'Fideos Carozzi 400g', 12); -- Dispara alerta amarilla
INSERT INTO inventario_minimarket VALUES (102, 1, 'Aceite Natura 1L', 0); -- Dispara alerta roja

INSERT INTO inventario_minimarket VALUES (200, 2, 'Coca Cola 2L', 5); -- Dispara alerta amarilla
INSERT INTO inventario_minimarket VALUES (201, 2, 'Cerveza Cristal Lata', 40);

COMMIT;
