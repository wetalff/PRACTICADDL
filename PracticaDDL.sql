/* ================================================
   SCRIPT: bd_universidad
   Motor:  Microsoft SQL Server 2019/2022
   Autor:  Alfredo Montalvan
   Fecha:  26/5/26
   ================================================ */

-- ============ SECCIÓN DOWN (limpiar primero) ============

-- SINGLE_USER pone la base de datos en modo de un solo usuario.
-- WITH ROLLBACK IMMEDIATE desconecta las sesiones activas
-- y cancela transacciones pendientes inmediatamente.
-- Esto permite ejecutar DROP DATABASE sin errores por conexiones abiertas.
USE master; 
GO
ALTER DATABASE bd_universidad
SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

DROP DATABASE bd_universidad;
GO

USE master; 
GO
DROP DATABASE IF EXISTS bd_universidad; 
GO

-- ============ SECCIÓN UP (construir) ============
CREATE DATABASE bd_universidad; 
GO
USE bd_universidad; 
GO
-- La función del "GO" es indicar que todas las instrucciones anteriores
-- deben enviarse y ejecutarse como un bloque independiente.

CREATE TABLE Carrera (
    id_carrera INT IDENTITY(1,1) Constraint Pk_idCarrera Primary key, 
    nombre NVARCHAR(150) NOT NULL, --Nvarchar para aceptar y evitar problemas con los acentos
    duracion_anios INT NOT NULL,
    modalidad VARCHAR(50) NOT NULL Constraint CK_Modalidad CHECK(modalidad in (N'Presencial', N'Virtual', N'Semipresencial')) 
    --Varchar debido a que los unicos valores que 
    --se aceptan quedan perfectamente bien con esa opcion 
    --ademas de que requiere menos espacio

    -- IDENTITY(1,1) se usa para generar automáticamente
    -- valores únicos para la clave primaria.
    -- El primer número (1) indica el valor inicial.
    -- El segundo número (1) indica el incremento.
);

CREATE TABLE Materia (
    id_materia INT IDENTITY(1,1) Constraint PK_idMateria Primary key,
    -- IDENTITY(1,1) se usa para generar automáticamente
    -- valores únicos para la clave primaria.
    codigo VARCHAR(20) NOT NULL Constraint UQ_codigo UNIQUE,
    -- VARCHAR se usa en codigo porque normalmente
    -- almacena texto corto sin caracteres especiales.
    nombre NVARCHAR(100) NOT NULL,
    -- NVARCHAR se usa en nombre para permitir
    -- caracteres Unicode y acentos.
    creditos TINYINT NOT NULL,
    semestre TINYINT NOT NULL
);


CREATE TABLE ESTUDIANTE (
    id_estudiante   INT IDENTITY(1,1) Constraint PK_idEstduiante PRIMARY KEY,
        -- IDENTITY(1,1) se usa para generar automáticamente
        -- valores únicos para la clave primaria.
    carnet          NVARCHAR(10)  NOT NULL Constraint UQ_Carnet UNIQUE,
    -- NVARCHAR se usa en carnet porque puede incluir
    -- letras, números y caracteres especiales.
    nombre_completo NVARCHAR(150) NOT NULL,
    -- NVARCHAR se usa en nombre para permitir
    -- caracteres Unicode y acentos.
    fecha_nacimiento DATE          NULL,
    email           NVARCHAR(100) NOT NULL Constraint UQ_email UNIQUE,
    -- NVARCHAR se usa en email para admitir caracteres Unicode.
    id_carrera      INT           NOT NULL,
    CONSTRAINT fk_estudiante_carrera FOREIGN KEY (id_carrera)
        REFERENCES CARRERA (id_carrera)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
        -- La FOREIGN KEY garantiza que el estudiante
        -- solo pueda pertenecer a una carrera existente.

        -- Diferencia semántica:
--   * RESTRICT:
--       Impide la operación inmediatamente si existen
--       registros relacionados.
--
--   * NO ACTION:
--       Permite que la validación se realice al finalizar
--       la instrucción SQL. En SQL Server el comportamiento
--       práctico es equivalente a RESTRICT.
);

CREATE TABLE Inscripcion (
    id_inscripcion INT PRIMARY KEY IDENTITY(1,1),
    -- IDENTITY(1,1) se usa para generar automáticamente
    -- valores únicos para la clave primaria.

    id_estudiante INT NOT NULL,
    id_materia INT NOT NULL,

    anio SMALLINT NOT NULL
    CONSTRAINT ck_anio_valido
    CHECK (anio BETWEEN 2000 AND 2099),

    periodo NVARCHAR(3) NOT NULL
    CONSTRAINT ck_periodo_valido
    CHECK (periodo IN (N'I', N'II', N'III')),
    -- NVARCHAR se usa en periodo para admitir texto Unicode.

    nota_final DECIMAL(4,2) NULL,

    -- nota_final permite NULL porque un estudiante puede
    -- estar inscrito y aún no tener calificación asignada.
    -- Esto permite registrar la inscripción antes de finalizar
    -- el período académico.

    CONSTRAINT fk_inscripcion_estudiante
    FOREIGN KEY (id_estudiante)
    REFERENCES Estudiante(id_estudiante),
    -- La FOREIGN KEY garantiza que la inscripción
    -- pertenezca a un estudiante existente.


    CONSTRAINT fk_inscripcion_materia
    FOREIGN KEY (id_materia)
    REFERENCES Materia(id_materia),
    -- La FOREIGN KEY garantiza que la inscripción
    -- corresponda a una materia existente.


    CONSTRAINT uq_inscripcion
    UNIQUE (id_estudiante, id_materia, anio, periodo)
);

ALTER TABLE ESTUDIANTE
    ADD telefono NVARCHAR(20) NULL;
GO
-- NVARCHAR se usa en telefono para admitir
-- caracteres especiales como + o espacios.


ALTER TABLE ESTUDIANTE
    ADD
        estado   NVARCHAR(10) NOT NULL DEFAULT N'Activo',
        CONSTRAINT ck_estado_valido CHECK (estado IN (N'Activo', N'Inactivo'));
        -- NVARCHAR se usa en estado para permitir texto Unicode.
GO

Alter table Materia
  ADD
  descripcion NVARCHAR(MAX) Null;
  -- NVARCHAR(MAX) permite almacenar textos largos
  -- con caracteres Unicode.

  go
   

ALTER TABLE ESTUDIANTE
    ALTER COLUMN telefono NVARCHAR(25) NULL;
GO
-- NVARCHAR se usa en telefono para admitir
-- caracteres especiales como + o espacios.


EXEC sp_rename
    N'CARRERA.duracion_anios',  
    N'duracion',                 
    N'COLUMN';                    
GO
-- Al renombrar una columna con sp_rename, SQL Server
-- muestra una advertencia porque objetos dependientes
-- como vistas, procedimientos o funciones pueden romperse
-- si usan el nombre anterior de la columna.
-- SQL Server no actualiza automáticamente esas referencias.

ALTER TABLE Inscripcion
    ALTER COLUMN nota_final DECIMAL(5, 2) NULL;
GO

SELECT name, definition
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID(N'Materia');

SELECT name, type_desc
FROM sys.objects
WHERE parent_object_id = OBJECT_ID(N'Materia')
AND type IN ('C','D','F','PK','UQ');

-- Ver todos los constraints de la BD
SELECT TABLE_NAME, CONSTRAINT_NAME, CONSTRAINT_TYPE
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
ORDER BY TABLE_NAME;


SELECT SERVERPROPERTY('Collation');

Alter table Carrera
Add CONSTRAINT ck_duracion_carrera CHECK (duracion BETWEEN 3 AND 6)
go

Alter table Materia
Add CONSTRAINT ck_semestre_carrera CHECK (semestre BETWEEN 1 AND 12)
go


CREATE NONCLUSTERED INDEX 
IX_estudiante_email ON ESTUDIANTE (email);

-- CLUSTERED ordena físicamente los datos de la tabla.
-- La PRIMARY KEY crea este tipo automáticamente.

-- NONCLUSTERED no ordena los datos; crea una estructura aparte
-- para acelerar búsquedas sobre otras columnas.


SELECT name, definition
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID(N'Materia');

ALTER TABLE Materia DROP CONSTRAINT ck_semestre_carrera;

SELECT d.name AS default_name
FROM sys.default_constraints d
JOIN sys.columns c ON d.parent_column_id = c.column_id
    AND d.parent_object_id = c.object_id
WHERE c.object_id = OBJECT_ID(N'Materia')
    AND c.name = N'descripcion';

    ALTER TABLE MATERIA
    DROP COLUMN descripcion;
GO




--DROP TABLE IF EXISTS Inscripcion;
--DROP TABLE IF EXISTS ESTUDIANTE;
--DROP TABLE IF EXISTS Materia;
--DROP TABLE IF EXISTS Carrera;
--GO

-- Se necesita eliminar en ese 
-- orden debido a que se va eliminado primero las 
-- tablas que son dependientes o hijas por foreign key y una vez se eliminan 
-- las tablas hijas se pueden eliminar las tablas principiales
-- o que no poseen foreign key

-- SQL Server no soporta DROP TABLE ... CASCADE
-- como otros motores de bases de datos.
--
-- Primero deben eliminarse
-- las restricciones dependientes (FOREIGN KEY)
-- y después eliminar la tabla.
--
-- Esto evita borrar objetos relacionados
-- accidentalmente y da mayor control
-- sobre la integridad de la base de datos.

Insert into Materia (codigo, nombre, creditos, semestre) 
values
('BDD','Basededatos',5,2),
('QMC','Quimico',2,6),
('MTM', 'MatematicaBasica', 2,4)



Delete from Materia
where codigo = 'MTM';
Delete from Materia
where codigo = 'BDD';
Delete from Materia
where codigo = 'QMC';



INSERT INTO Carrera (nombre, duracion, modalidad)
VALUES 
(N'Ingeniería en Sistemas', 5, N'Presencial'),
(N'Administración de Empresas', 4, N'Semipresencial'),
(N'Diseño Gráfico', 4, N'Virtual'),
(N'Contabilidad', 5, N'Presencial'),
(N'Derecho', 5, N'Presencial');

INSERT INTO Materia (codigo, nombre, creditos, semestre)
VALUES
('MAT101', 'Matemática Básica', 4, 1),
('PRO102', 'Programación I', 5, 1),
('BD201', 'Base de Datos', 4, 3),
('ADM110', 'Introducción a la Administración', 3, 1),
('DER210', 'Derecho Civil', 4, 4),
('HNH210','Historia Nacional',2,2);

INSERT INTO ESTUDIANTE 
(carnet, nombre_completo, fecha_nacimiento, email, id_carrera, telefono)
VALUES
(N'2025001', N'Juan Pérez López', '2004-05-12', N'juanperez@gmail.com', 1,'88888888'),
(N'2025002', N'María González Ruiz', '2003-11-20', N'mariagonzalez@gmail.com', 2,'55555555'),
(N'2025003', N'Carlos Hernández', '2005-01-15', N'carlosh@gmail.com', 1,'99999999'),
(N'2025004', N'Ana Martínez', '2002-07-08', N'anamartinez@gmail.com', 3,'11111111'),
(N'2025005', N'Luis Torres', '2004-09-30', N'luistorres@gmail.com', 4,'22222222');

INSERT INTO Inscripcion
(id_estudiante, id_materia, anio, periodo, nota_final)
VALUES
(1, 4, 2025, N'I',   85.50),
(1, 5, 2025, N'I',   90.00),
(2, 6, 2025, N'I',   88.75),
(3, 7, 2025, N'II',  79.00),
(4, 8, 2025, N'II',  92.25),
(5, 9, 2025, N'I',   70.00);



Begin transaction TRUNCATE TABLE Inscripcion Rollback

Select * from Carrera
Select * from Materia
Select * from ESTUDIANTE
Select * from Inscripcion