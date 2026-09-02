# Menú Listo 🍳📋

<p align="center">
  <strong>Tu asistente culinario integral para organizar tus comidas semanales, recetario inteligente con escáner OCR y lista de compras sin duplicados de forma 100% offline y privada.</strong>
</p>

---

## ✨ Características Principales

### 📖 1. Recetario Inteligente & Secciones
* **Editor Unificado:** Ingreso rápido de ingredientes y pasos en campos multilínea con detección inteligente de cantidades, unidades y tiempos.
* **Secciones Automáticas:** Organiza recetas complejas con encabezados terminados en `:` (ej. `Para la masa:`, `Para la salsa:`).
* **Escáner OCR de Fotos:** Escanea libros y recetas manuscritas usando reconocimiento óptico de caracteres en el dispositivo (Google ML Kit).
* **Importador Web:** Importa recetas desde enlaces web con un solo toque.
* **Escalado Dinámico de Porciones:** Ajusta automáticamente las cantidades de todos los ingredientes según la cantidad de comensales.

### ⏱️ 2. Temporizadores Interactivos & Modo Cocina
* **Temporizadores en Recetas:** Detección de tiempos en las instrucciones (`⏱️ 15 min`) con barra flotante inferior de cuenta regresiva, +1 min y alertas sonoras/visuales.
* **Modo Cocina Pantalla Completa:** Mantiene la pantalla encendida (Wakelock), muestra pasos en texto grande y lista de ingredientes siempre accesible.
* **Control Manos Libres (Hands-Free):** Avanza y retrocede pasos pasando la mano frente a la cámara frontal del dispositivo sin tocar la pantalla con las manos sucias.

### 📅 3. Planificador Semanal & Plantillas ("Mis Menús")
* **Planificación por Momentos:** Desayuno, Almuerzo, Merienda y Cena para los 7 días de la semana.
* **Plantillas Guardadas:** Guarda semanas completas como plantillas reutilizables (ej. *Semana Económica*, *Semana Express*) y aplícalas en un toque.
* **Relleno Automático:** Algoritmo de sugerencias que llena espacios vacíos con recetas del catálogo.
* **Repetir Semana Anterior:** Clona la planificación previa con un clic.

### 🔍 4. Buscador de Heladera ("¿Qué cocino hoy?")
* Selecciona los ingredientes que tienes a mano y obtén sugerencias de recetas ordenadas por porcentaje de coincidencia.

### 🛒 5. Lista de Compras Inteligente & Modo Súper
* **Consolidación sin Duplicados:** Agrupa ingredientes idénticos sumando cantidades y estandarizando unidades (g, kg, ml, l, cda, u).
* **Categorización por Góndola:** Ordena automáticamente por Verdulería, Carnicería, Lácteos, Despensa y General.
* **Revisión de Alacena:** Modal previo para desmarcar productos básicos que ya tienes en casa.
* **Gestos Bidireccionales:** Desliza a la derecha para completar (fondo verde) o a la izquierda para eliminar (fondo rojo).
* **Modo Súper:** Interfaz de compras enfocada para usar dentro del supermercado con checkbox táctil grande.
* **Compartir:** Exporta la lista formateada a WhatsApp, Notas o correo.

---

## 🎨 Animaciones, Transiciones y Respuesta Táctil

* **Hero Transitions:** Transición continua de imágenes entre la lista de recetas y el detalle.
* **Haptic Feedback:** Respuesta háptica integrada en el tachado de ingredientes, temporizadores, porciones y navegación de pasos.
* **Micro-interacciones:** Animaciones con `AnimatedSwitcher` en el selector de porciones y `TweenAnimationBuilder` en la barra de progreso de cocción.

---

## ⚡ Rendimiento y Tamaño Optimizado

* **Minificación R8 & Shrink Resources:** Reducción de ~40% del tamaño del binario en release.
* **Límites de Decodificación en Memoria (`cacheWidth`):** Scroll fluido a 60/120 FPS sin consumo excesivo de RAM.
* **Entrega Dinámica de Modelos ML Kit:** Carga bajo demanda vía Google Play Services.

---

## 🛠️ Tecnologías

* **Framework:** Flutter 3.x / Dart 3.x
* **State Management:** Riverpod 2.x
* **Base de Datos:** SQLite (`sqflite`) 100% offline
* **Visión Artificial:** Google ML Kit Text Recognition
* **Cámara:** Camera Plugin (Hands-free optical gesture recognition)
* **Audio & Pantalla:** Wakelock Plus, Intl Localization (ES / EN)
