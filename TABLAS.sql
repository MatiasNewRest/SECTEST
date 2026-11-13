-- 1. Tabla de Usuarios
CREATE TABLE usuario (
    id_usuario INT IDENTITY(1,1) PRIMARY KEY,
    rut_usuario VARCHAR(12) NOT NULL UNIQUE, -- Ej: '12345678-9'
    nombre_usuario NVARCHAR(100) NOT NULL,
    correo NVARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NULL, -- Longitud para hashes modernos (Argon2 / Bcrypt)
    activo BIT NOT NULL DEFAULT 1,
    -- Mejoras de seguridad para Login:
    intentos_fallidos SMALLINT NOT NULL DEFAULT 0,
    requiere_cambio_password BIT NOT NULL CONSTRAINT df_usuario_requiere_cambio_password DEFAULT 0,
    password_cambiada_en DATETIME2 NULL,
    bloqueado_hasta DATETIME2 NULL,
    ultimo_acceso DATETIME2 NULL,
    fecha_creacion DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    fecha_actualizacion DATETIME2 NOT NULL DEFAULT SYSDATETIME()
    
);
GO

-- 2. Tabla de Roles
CREATE TABLE rol (
    id_rol INT IDENTITY(1,1) PRIMARY KEY,
    nombre_rol NVARCHAR(50) NOT NULL UNIQUE,
    descripcion NVARCHAR(255) NULL,
    activo BIT NOT NULL DEFAULT 1
);
GO

-- 3. Tabla de Permisos (Granularidad: recurso + acción)
CREATE TABLE permiso (
    id_permiso INT IDENTITY(1,1) PRIMARY KEY,
    codigo_permiso VARCHAR(100) NOT NULL UNIQUE, -- Ej: 'usuarios.crear', 'reportes.ver'
    nombre_permiso NVARCHAR(100) NOT NULL,
    descripcion NVARCHAR(255) NULL
);
GO

-- 4. Tabla de Menús (Navegación dinámica según permisos)
CREATE TABLE menu (
    id_menu INT IDENTITY(1,1) PRIMARY KEY,
    nombre_menu NVARCHAR(100) NOT NULL,
    url NVARCHAR(255) NULL, -- NULL si es un menú desplegable contenedor
    icono VARCHAR(50) NULL, -- Útil para el frontend
    orden INT NOT NULL DEFAULT 0, -- Controla la posición visual
    id_padre INT NULL,
    id_permiso INT NULL, -- NULL si el menú es público para cualquier usuario autenticado
    activo BIT NOT NULL DEFAULT 1,
    CONSTRAINT fk_menu_padre FOREIGN KEY (id_padre) REFERENCES menu(id_menu) ON DELETE NO ACTION,
    CONSTRAINT fk_menu_permiso FOREIGN KEY (id_permiso) REFERENCES permiso(id_permiso) ON DELETE SET NULL
);
GO

-- 5. Tabla Puente: Usuario - Rol (N:M)
CREATE TABLE usuario_rol (
    id_usuario INT NOT NULL,
    id_rol INT NOT NULL,
    fecha_asignacion DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    PRIMARY KEY (id_usuario, id_rol),
    CONSTRAINT fk_ur_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    CONSTRAINT fk_ur_rol FOREIGN KEY (id_rol) REFERENCES rol(id_rol) ON DELETE CASCADE
);
GO

-- 6. Tabla Puente: Rol - Permiso (N:M)
CREATE TABLE rol_permiso (
    id_rol INT NOT NULL,
    id_permiso INT NOT NULL,
    PRIMARY KEY (id_rol, id_permiso),
    CONSTRAINT fk_rp_rol FOREIGN KEY (id_rol) REFERENCES rol(id_rol) ON DELETE CASCADE,
    CONSTRAINT fk_rp_permiso FOREIGN KEY (id_permiso) REFERENCES permiso(id_permiso) ON DELETE CASCADE
);
GO

-- 7. Tabla de Auditoría
CREATE TABLE auditoria (
    id_auditoria BIGINT IDENTITY(1,1) PRIMARY KEY,
    id_usuario INT NULL, -- NULL permite registrar intentos de login de usuarios no identificados o procesos del sistema
    accion VARCHAR(50) NOT NULL, -- Ej: 'LOGIN_EXITOSO', 'LOGIN_FALLIDO', 'INSERT', 'UPDATE', 'DELETE'
    tabla_afectada VARCHAR(100) NULL,
    registro_id VARCHAR(50) NULL, -- ID del registro afectado en la tabla
    -- datos_anteriores NVARCHAR(MAX) NULL CHECK (datos_anteriores IS NULL OR ISJSON(datos_anteriores) = 1), --pensado para futuro falta analizar 
    -- datos_nuevos NVARCHAR(MAX) NULL CHECK (datos_nuevos IS NULL OR ISJSON(datos_nuevos) = 1),  --pensado para futuro falta analizar
    ip_origen VARCHAR(45) NULL, -- Soporta IPv4 e IPv6
    user_agent NVARCHAR(MAX) NULL, -- Navegador / dispositivo desde donde se operó
    fecha_registro DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT fk_auditoria_usuario FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario) ON DELETE SET NULL
);
GO

-- Índices recomendados para acelerar el flujo de Login y carga de menús
-- Nota: correo y rut_usuario ya tienen índices únicos automáticos por la restricción UNIQUE,
-- pero si deseas mantener índices explícitos o incluir columnas (INCLUDE), puedes usarlos así:
CREATE INDEX idx_menu_padre ON menu(id_padre);
CREATE INDEX idx_auditoria_usuario_fecha ON auditoria(id_usuario, fecha_registro);
GO



CREATE TABLE password_reset_codes
(
    id INT IDENTITY(1,1) PRIMARY KEY,

    usuario_id INT NOT NULL,

    codigo VARCHAR(6) NOT NULL,

    fecha_creacion DATETIME2 NOT NULL DEFAULT GETDATE(),

    fecha_expiracion DATETIME2 NOT NULL,

    usado BIT NOT NULL DEFAULT 0,

    fecha_uso DATETIME2 NULL,

    CONSTRAINT FK_password_reset_codes_usuario
        FOREIGN KEY (usuario_id)
        REFERENCES usuario(id_usuario)
);
GO

CREATE INDEX IX_password_reset_codes_usuario
ON password_reset_codes(usuario_id);
GO

CREATE INDEX IX_password_reset_codes_codigo
ON password_reset_codes(codigo);
GO