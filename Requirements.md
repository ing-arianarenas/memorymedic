# 📱 Documento de Requerimientos del Sistema - MemoryMedic  
**Versión:** 1.0  
**Autor:** Arenas Martínez  
**Fecha:** 2025-10-28  

---

## 1. Introducción

### 1.1 Propósito
Este documento detalla los requerimientos funcionales, no funcionales y de interfaz de la aplicación móvil **MemoryMedic**, cuyo propósito es mejorar la adherencia a tratamientos médicos mediante recordatorios, monitoreo y sincronización entre dispositivos.

### 1.2 Alcance
La app permitirá registrar medicamentos, programar recordatorios, realizar seguimiento de la adherencia, manejar múltiples perfiles, autenticar usuarios y sincronizar datos en la nube.  
Incluye también pantallas de bienvenida, configuración personalizada, y un sistema de notificaciones push conectado con otros dispositivos.

---

## 2. Descripción general del sistema

### 2.1 Usuarios objetivo
- Pacientes que deben cumplir tratamientos prolongados.  
- Cuidadores o familiares que hacen seguimiento remoto.  
- Profesionales de salud que supervisan adherencia.

### 2.2 Plataforma
- Aplicación móvil híbrida (Android/iOS).  
- Funcionamiento offline con sincronización automática al reconectarse.  
- Arquitectura basada en MVVM y base de datos local + nube (Firebase o Supabase).

---

## 3. Arquitectura del sistema
Módulos principales:
1. **Gestión de medicamentos**  
2. **Recordatorios y notificaciones push**  
3. **Autenticación y sincronización de usuarios**  
4. **Estadísticas y reportes**  
5. **Gestión de perfiles**  
6. **Configuración y preferencias**  
7. **Interfaz de inicio (Splash / Onboarding)**  

---

## 4. Pantallas principales y características

### 🚀 4.1 Splash Screen / Pantallas de bienvenida
**Propósito:** presentar el logotipo y cargar la app.  
**Elementos:**
- Logotipo MemoryMedic animado.  
- Frase motivacional (“Tu salud, en tus manos”).  
- Barra o animación de carga.  
- Duración máxima: 3 segundos.  
**Funciones:**
- Cargar dependencias locales y verificar sesión iniciada.  
- Redirigir a pantalla de autenticación o inicio.

---

### 🔐 4.2 Autenticación (Login / Registro / Recuperación)
**Propósito:** permitir acceso seguro y sincronización de usuarios.  
**Elementos:**
- Campos: correo, contraseña, opción “Recordar sesión”.  
- Botones: Iniciar sesión, Crear cuenta, Olvidé mi contraseña.  
- Opción de autenticación biométrica (huella / rostro).  
**Funciones:**
- Registro con validación de correo.  
- Sincronización con servidor remoto.  
- Sesión persistente local.  
- Cierre de sesión manual.  
- Recuperación de contraseña vía correo.

---

### 🏠 4.3 Home Screen - Lista de Medicamentos
**Propósito:** listar medicamentos activos y próximos horarios.  
**Elementos:**
- Lista de medicamentos con próxima dosis.  
- Estado activo/inactivo.  
- Botón flotante “+” para agregar medicamento.  
**Funciones:**
- Navegación al detalle.  
- Activar/desactivar recordatorios.  
- Sincronizar datos con la nube.

---

### 💊 4.4 Add Medication Screen - Agregar Medicamento
**Propósito:** registrar un nuevo tratamiento.  
**Campos:**
- Nombre, imagen, dosis, frecuencia, cantidad total, duración.  
- Hora de inicio y sonido de recordatorio.  
- Tiempo de posposición (por defecto 15 min).  
**Funciones:**
- Validar datos antes de guardar.  
- Subir imagen a almacenamiento remoto.  
- Guardar registro local y sincronizar en la nube.

---

### ⏰ 4.5 Medication Detail Screen - Detalle del Medicamento
**Propósito:** visualizar dosis próxima y registrar acción.  
**Elementos:**
- Cuenta regresiva.  
- Botones: **Tomar ahora**, **Posponer**, **Omitir**.  
- Dosis y frecuencia configurada.  
**Funciones:**
- Registrar acción (cumplida, pospuesta, omitida).  
- Actualizar estadísticas en tiempo real.  
- Sincronizar acción con la nube para otros dispositivos conectados.

---

### 📊 4.6 Statistics Screen - Estadísticas
**Propósito:** mostrar nivel de adherencia.  
**Elementos:**
- Indicador circular de adherencia global.  
- Gráfico diario/semanal/mensual.  
- Lista con adherencia por medicamento.  
- Botón “Exportar PDF”.  
**Funciones:**
- Calcular estadísticas locales y sincronizadas.  
- Exportar informe para profesionales o cuidadores.  

---

### 👨‍👩‍👧‍👦 4.7 Profile Selector Screen - Perfiles
**Propósito:** administrar múltiples perfiles.  
**Elementos:**
- Tarjetas con imagen, nombre y color.  
- Botón “Agregar perfil”.  
**Funciones:**
- Cambiar perfil activo.  
- Crear, editar o eliminar perfiles.  
- Sincronizar perfiles entre dispositivos autorizados.

---

### 🔔 4.8 Notification Screen - Notificaciones Push
**Propósito:** alertar sobre la toma del medicamento.  
**Elementos:**
- Nombre, dosis, hora.  
- Botones de acción rápida: **Tomar**, **Posponer**, **Omitir**.  
**Funciones:**
- Ejecutar acción desde la notificación.  
- Notificaciones automáticas push (Firebase Cloud Messaging).  
- Registro sincronizado en tiempo real para otros usuarios.

---

### ⚙️ 4.9 Settings Screen - Configuración
**Propósito:** personalizar experiencia y administrar cuenta.  
**Elementos:**
- Sección “Cuenta”: cambiar contraseña, cerrar sesión.  
- Sección “Notificaciones”: activar sonido, vibración, hora silenciosa.  
- Sección “Idioma y tema”: modo claro/oscuro, idioma app.  
- Sección “Sincronización”: estado de respaldo y última sincronización.  
**Funciones:**
- Actualizar preferencias locales y en la nube.  
- Seleccionar temas de interfaz.  
- Sincronizar manualmente con servidor.

---

## 5. Requerimientos no funcionales

| Categoría | Descripción |
|------------|-------------|
| **Usabilidad** | Interfaz accesible y legible (tamaño fuente >16px). |
| **Seguridad** | Autenticación segura y cifrado AES-256. |
| **Privacidad** | Cumplimiento RGPD y Ley 1581 (Colombia). |
| **Rendimiento** | Tiempo de carga ≤ 3 s; notificaciones ≤ 2 s de retraso. |
| **Compatibilidad** | Android 10+ / iOS 13+. |
| **Disponibilidad** | Funcionalidad offline completa. |
| **Escalabilidad** | Sincronización multiusuario vía API REST o Firebase. |

---

## 6. Requerimientos opcionales
- Copia de seguridad automática.  
- Recordatorios por voz.  
---

## 7. Restricciones
- No sustituye orientación médica profesional.  
- Requiere permisos de cámara, notificaciones y almacenamiento.  
- Solo disponible para mayores de 13 años.

---

_Fin del documento._
