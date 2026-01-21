## Visión general del ecosistema

Descripción macro del ecosistema, sus objetivos estratégicos, actores implicados y el valor que aporta.  
(Este apartado se completará y refinará a medida que me vayas pasando información del proyecto.)

### Objetivos estratégicos
- [ ] Definir objetivos de negocio (KPI, métricas, revenue, retención, etc.)
- [ ] Definir objetivos de producto (problemas que resolvemos, para quién y con qué propuesta de valor)
- [ ] Definir objetivos técnicos (escalabilidad, rendimiento, seguridad, mantenibilidad)

### Alcance inicial (versión macro, no MVP)
- [ ] Listar todos los módulos y funcionalidades que formarán parte de la primera gran versión
- [ ] Clasificar módulos por dominio funcional (auth, onboarding, coaching, IA, analítica, etc.)
- [ ] Identificar dependencias críticas entre módulos

---

## Mapa de producto y dominios

### Dominios funcionales principales
- [ ] Definir dominios (p.ej. `User`, `Training`, `Nutrition`, `Analytics`, `AI/Recommendations`, `Gamification`, `Recovery`, `Devices`)
- [ ] Describir responsabilidades de cada dominio
- [ ] Identificar límites de contexto (bounded contexts) entre dominios

### Componentes del ecosistema
- [ ] Listar todas las aplicaciones/servicios (app móvil, backend, panel admin, microservicios, worker jobs, etc.)
- [ ] Definir relaciones entre componentes (diagrama de alto nivel)
- [ ] Definir fuentes de datos (bases de datos, APIs externas, proveedores terceros)

---

## Mapa funcional: Entrenadores Virtuales Personalizados

En esta sección se definen las funcionalidades núcleo de la app y se conectan con dominios y componentes técnicos.

### 1. Entrenadores virtuales personalizados

**Descripción funcional**  
La IA analiza datos del usuario (historial de actividad, preferencias, estado físico y objetivos) para crear entrenamientos altamente personalizados, adaptarlos según progreso y ofrecer consejos en tiempo real.

- **Objetivo principal del módulo**
  - Crear un **entrenador virtual siempre disponible** que:
    - Conozca el contexto completo del usuario (perfil, hábitos, progreso, lesiones, preferencias).
    - Genere y adapte planes de entrenamiento de forma continua.
    - Interactúe con el usuario (feedback, motivación, explicación de decisiones).

- **Modelo de dominio (macro)**
  - Entidades principales:
    - `TrainingUserProfile`: datos base (edad, género, nivel, historial de lesiones, disponibilidad, equipamiento).
    - `TrainingGoal`: objetivos concretos (pérdida de peso, ganancia muscular, rendimiento específico).
    - `TrainingPlan`: plan agregado (semanal/mensual) compuesto por sesiones.
    - `TrainingSession`: sesión concreta (tipo, duración, intensidad, ejercicios).
    - `Exercise`: definición de ejercicio (tipo, grupo muscular, equipamiento, nivel).
    - `ExercisePrescription`: configuración específica de un ejercicio (series, reps, tempo, descanso).
    - `TrainingPerformance`: datos de ejecución real (reps hechas, peso usado, tiempos).
    - `TrainingFeedback`: feedback explícito del usuario (RPE, dolor, fatiga, disfrute).

- **Flujos clave**
  - Onboarding:
    - Usuario completa cuestionario inicial → se crea `TrainingUserProfile` + `TrainingGoal`.
    - La IA / motor de reglas genera un `TrainingPlan` inicial (p.ej. 4–8 semanas).
  - Ejecución de sesión:
    - App muestra `TrainingSession` con su lista de ejercicios (`ExercisePrescription`).
    - Usuario ejecuta la sesión → se registran `TrainingPerformance` + `TrainingFeedback`.
  - Adaptación:
    - Motor analiza desempeño y feedback → ajusta futuras sesiones del `TrainingPlan`.
  - Revisión periódica:
    - Cada X semanas se reevalúan objetivos, adherencia y progreso → posible recalibración del plan.

- **Checklist de diseño funcional**
  - [ ] Definir modelo de usuario de entrenamiento (objetivos, restricciones, preferencias, historial)
  - [ ] Definir tipos de planes de entrenamiento (fuerza, cardio, HIIT, movilidad, mixtos)
  - [ ] Definir reglas de personalización (nivel, frecuencia, disponibilidad, equipamiento)
  - [ ] Definir lógica de adaptación dinámica según progreso y adherencia

- **Checklist de diseño de IA**
  - [ ] Definir features de entrada para la IA (métricas de rendimiento, frecuencia, RPE, etc.)
  - [ ] Definir outputs de la IA (plan semanal, ajustes propuestos, recomendaciones puntuales)
  - [ ] Definir criterios de evaluación de la calidad de los planes generados

- **Diseño de IA (macro)**
  - Inputs:
    - Datos estáticos: `TrainingUserProfile`, `TrainingGoal`, historial de lesiones.
    - Datos dinámicos: `TrainingPerformance`, `TrainingFeedback`, métricas de sensores (FC, velocidad, etc.).
  - Outputs:
    - Generación inicial de `TrainingPlan`.
    - Ajustes incrementales (cambio de volumen, intensidad, ejercicios, frecuencia).
    - Recomendaciones puntuales durante sesiones (p.ej. “reduce una serie hoy”).
  - Enfoque evolutivo:
    - Versión inicial basada en reglas + modelos simples.
    - Evolución hacia modelos secuenciales (series temporales) para predecir respuesta al entrenamiento.

- **Checklist técnica**
  - [ ] Definir contratos API para creación/actualización de planes personalizados
  - [ ] Definir almacenamiento de planes, historial y versiones
  - [ ] Definir integración con el motor de recomendaciones/IA

- **Integraciones clave**
  - Con `Seguimiento de progreso inteligente` para consumir datos de rendimiento reales.
  - Con `Gamificación adaptativa` para definir retos coherentes con el plan.
  - Con `Nutrición inteligente` para alinear carga de entrenamiento y calorías/macros.

- **Monetización asociada**
  - Capa gratuita: plan más estático con pocas adaptaciones.
  - Capa premium: plan dinámico + revisiones frecuentes + reportes avanzados.
  - Capa elite: entrenador híbrido IA + humano (consultas con entrenadores reales).

---

### 2. Seguimiento de progreso inteligente

**Descripción funcional**  
Uso de sensores (GPS, acelerómetros, wearables, etc.) para seguir el progreso de los usuarios; predicción de metas alcanzables, sugerencia de ajustes de intensidad y análisis de rendimiento detallado.

- **Checklist de datos**
  - [ ] Definir eventos y métricas que se recogen durante los entrenamientos
  - [ ] Definir modelo de sesión de entrenamiento (tiempo, intensidad, volumen, carga, etc.)
  - [ ] Definir integración con dispositivos/sensores (protocolos, frecuencia, formatos)

- **Checklist de análisis**
  - [ ] Definir algoritmos para cálculo de rendimiento (p.ej. carga aguda/crónica, zonas de FC)
  - [ ] Definir lógica para predicción de metas alcanzables
  - [ ] Definir reglas para sugerencia de ajustes (subir/bajar intensidad, volumen, frecuencia)

- **Checklist de UX**
  - [ ] Diseñar visualizaciones de progreso (gráficas, tendencias, comparativas)
  - [ ] Definir notificaciones y momentos clave de feedback al usuario

---

### 3. Reconocimiento de movimiento y corrección de técnica

**Descripción funcional**  
Uso de análisis de imagen/vídeo para reconocer movimientos, validar postura y forma, y ofrecer feedback en tiempo casi real para evitar lesiones y mejorar eficiencia.

- **Checklist de requisitos**
  - [ ] Definir casos de uso (ejercicios concretos a cubrir en la primera versión macro)
  - [ ] Definir dispositivos soportados (móvil, webcam, cámaras externas)
  - [ ] Definir niveles de latencia y precisión aceptables

- **Checklist de IA / CV**
  - [ ] Definir puntos clave (keypoints) a detectar por ejercicio
  - [ ] Definir métricas de calidad de la detección (precisión de ángulos, estabilidad)
  - [ ] Definir tipos de feedback (alertas de mala postura, correcciones, recomendaciones)

- **Checklist técnica**
  - [ ] Definir arquitectura de procesamiento (on-device vs cloud)
  - [ ] Definir APIs/SDK para el módulo de visión por computador

---

### 4. Nutrición inteligente

**Descripción funcional**  
Recomendación de dietas personalizadas según objetivos (pérdida de peso, ganancia muscular, rendimiento) analizando ingesta, gasto energético y contexto del entrenamiento.

- **Checklist funcional**
  - [ ] Definir modelo nutricional del usuario (objetivos, restricciones, intolerancias, preferencias)
  - [ ] Definir modelo de alimentos y recetas (macro/micronutrientes, porciones, etiquetas)
  - [ ] Definir flujos de registro de comidas (manual, escaneo, plantillas, IA)

- **Checklist de IA**
  - [ ] Definir inputs para recomendación de planes de alimentación
  - [ ] Definir outputs (plan diario/semanal, snacks, ajustes según progreso)
  - [ ] Definir reglas de alineación con el plan de entrenamiento

- **Checklist técnica**
  - [ ] Definir integración con el dominio de `Training` para coherencia calorías/volumen
  - [ ] Definir almacenamiento y versionado de planes nutricionales

---

### 5. Gamificación adaptativa

**Descripción funcional**  
Adaptar desafíos, misiones y recompensas según nivel, comportamiento y progreso del usuario para aumentar engagement y adherencia.

- **Checklist de diseño**
  - [ ] Definir sistema de puntos, niveles, badges y retos
  - [ ] Definir mecánicas de progresión adaptativa (subida de dificultad, retos dinámicos)
  - [ ] Definir reglas para evitar frustración o burnout

- **Checklist de IA**
  - [ ] Definir señales para adaptar gamificación (abandono, bajada de frecuencia, estancamiento)
  - [ ] Definir modelos para recomendar retos personalizados

- **Checklist técnica**
  - [ ] Definir eventos de juego y esquema de datos
  - [ ] Definir APIs para front (mostrar progreso, reclamar recompensas, etc.)

---

### 6. Asistente de entrenamiento en tiempo real

**Descripción funcional**  
Asistente basado en IA que interactúa en tiempo real con el usuario, sugiriendo cambios en el entrenamiento y ofreciendo motivación y soporte contextual.

- **Objetivo principal del módulo**
  - Crear un **compañero de entrenamiento virtual** que:
    - Guíe la sesión minuto a minuto (instrucciones, tiempos, descansos).
    - Adapte la sesión según la respuesta física y percepción del usuario.
    - Aporte motivación y contexto sin que el usuario tenga que mirar la pantalla.

- **Modelo de dominio (macro)**
  - Entidades principales:
    - `RealtimeContext`: estado en tiempo real del entreno (ejercicio actual, serie, tiempo restante, FC, RPE).
    - `CoachingInstruction`: instrucción concreta (texto/voz, tipo: técnica, ritmo, descanso, motivación).
    - `InterventionTrigger`: condición que dispara una intervención (fatiga, desviación de ritmo, mala adherencia, etc.).
    - `AssistantConfig`: preferencias del usuario (nivel de detalle, tono, frecuencia de mensajes, canal voz/texto).
    - `RealtimeAdjustment`: cambio aplicado al plan (bajar intensidad, añadir descanso, saltar ejercicio, etc.).

- **Flujos clave**
  - Inicio de sesión guiada:
    - Usuario inicia entrenamiento → se construye `RealtimeContext` inicial a partir de `TrainingSession` + sensores.
  - Bucle de sesión:
    - Cada intervalo (p.ej. 1–5 s) se actualiza `RealtimeContext` con datos de sensores y progreso.
    - Se evalúan `InterventionTrigger` → si se cumplen, se genera `CoachingInstruction` + posible `RealtimeAdjustment`.
  - Cierre de sesión:
    - Se genera resumen de sesión (métricas + intervenciones clave) y se persiste para análisis futuro.

- **Checklist funcional**
  - [ ] Definir tipos de interacción (voz, texto, notificaciones)
  - [ ] Definir triggers de intervención (fatiga, baja adherencia, desviación del plan)
  - [ ] Definir tono y personalidad del asistente

- **Checklist de IA**
  - [ ] Definir fuentes de contexto en tiempo real (ritmo, FC, RPE, duración)
  - [ ] Definir políticas de decisión (cuándo intervenir, qué recomendar)
  - [ ] Definir fallback a reglas cuando la IA no tenga suficiente confianza

- **Diseño de IA**
  - Fuentes de contexto:
    - Señales fisiológicas (FC, HRV aproximada si está disponible, ritmo, potencia).
    - Señales de desempeño (reps, tiempo por intervalo, cumplimiento del plan).
    - Señales de usuario (RPE, feedback explícito, pausa manual).
  - Lógica:
    - Capa de reglas para casos críticos (FC demasiado alta, dolor reportado).
    - Capa de modelos ML para decidir:
      - Cuándo intervenir sin molestar.
      - Qué tipo de mensaje es más efectivo para este usuario (historial de respuesta).

- **Integraciones clave**
  - Con `Entrenadores virtuales personalizados`: aplica `RealtimeAdjustment` sobre planes activos.
  - Con `Reconocimiento de movimiento`: usa errores de técnica para generar `CoachingInstruction` técnica.
  - Con `Gamificación adaptativa` y `Feedback motivacional`: dispara mensajes y recompensas contextuales.

- **Monetización asociada**
  - Plan premium con asistente por voz en tiempo real y personalización avanzada de tono/frecuencia.
  - Add-ons de packs de “personalidades” de entrenador (disciplinado, divertido, minimal, etc.).

---

### 7. Monitoreo de sueño y recuperación

**Descripción funcional**  
Análisis de patrones de sueño y recuperación para ajustar el entrenamiento y las recomendaciones de descanso.

- **Objetivo principal del módulo**
  - Entender **cuándo el cuerpo está preparado para rendir** y cuándo necesita descanso:
    - Integrar sueño, HRV, FC reposo y carga de entrenamiento.
    - Traducirlo en recomendaciones claras de entrenar fuerte, ligero o descansar.

- **Modelo de dominio (macro)**
  - Entidades principales:
    - `SleepSession`: bloque de sueño con fases estimadas (profundo, REM, ligero) y calidad.
    - `RecoveryIndex`: índice agregado de recuperación diaria (0–100) basado en sueño + HRV + carga.
    - `FatigueSignal`: señal de fatiga (aumento FC reposo, caída HRV, percepción de cansancio).
    - `RecoveryRecommendation`: recomendación diaria (descanso total, recuperación activa, intensidad moderada/alta).

- **Checklist de datos**
  - [ ] Definir métricas de sueño relevantes (duración, fases, interrupciones, consistencia)
  - [ ] Definir integración con dispositivos de seguimiento de sueño

- **Checklist de recomendaciones**
  - [ ] Definir reglas de ajuste de carga de entrenamiento según calidad de sueño
  - [ ] Definir recomendaciones de higiene del sueño y recuperación

- **Diseño de IA**
  - Inputs:
    - `SleepSession` + métricas de HRV/FC reposo + `WorkoutMetric` recientes.
  - Outputs:
    - `RecoveryIndex` diario.
    - `RecoveryRecommendation` + avisos de posible sobreentrenamiento.
  - Estrategias:
    - Reglas basadas en literatura (p.ej. subida FC reposo > X% → alerta) + modelos ML que aprendan el “baseline” personal.

- **Integraciones clave**
  - Con `Entrenamiento predictivo` y `Entrenadores virtuales personalizados`:
    - Adaptar automáticamente el volumen e intensidad según `RecoveryIndex`.
  - Con `Nutrición inteligente`:
    - Ajustar ingesta calórica/proteica los días de recuperación alta o baja.

- **Monetización asociada**
  - Panel de recuperación avanzado y recomendaciones pro-only.
  - Packs de contenido (protocolos de sueño/recuperación, vídeos guiados, etc.) ligados a este módulo.

---

### 8. Entrenamiento predictivo

**Descripción funcional**  
Uso de IA para predecir la siguiente etapa óptima del entrenamiento, proponiendo variaciones para superar estancamientos.

- **Objetivo principal del módulo**
  - Pasar de un entrenamiento reactivo a uno **proactivo**, capaz de:
    - Prever cuándo el usuario se va a estancar o sobrecargar.
    - Ajustar el plan antes de que eso ocurra.
    - Estimar cuándo cumplirá determinados hitos (tiempos, cargas, volúmenes).

- **Modelo de dominio (macro)**
  - Entidades principales:
    - `PerformanceTimeSeries`: series temporales de métricas clave (tiempos, cargas, volúmenes, RPE).
    - `PerformanceForecast`: predicción de una métrica concreta en un horizonte (días/semanas).
    - `PlateauRisk`: probabilidad de estancamiento en un período futuro.
    - `PredictiveAdjustment`: propuesta de cambio de plan (nueva distribución de cargas, tipo de estímulo, etc.).

- **Checklist de modelado**
  - [ ] Definir indicadores de estancamiento (plateau, fatiga acumulada, baja mejora)
  - [ ] Definir estrategias de variación (cambios de volumen, intensidad, tipo de estímulo)

- **Checklist técnica**
  - [ ] Definir frecuencia de reevaluación del plan
  - [ ] Definir cómo se comunican y aplican los cambios en el plan actual

- **Diseño de IA**
  - Técnicas:
    - Modelos de series temporales (p.ej. regresión, modelos autoregresivos, árboles gradient boosting sobre features de ventana).
  - Tareas:
    - Predicción de rendimiento (p.ej. tiempo 5K, 1RM estimada).
    - Estimación de `PlateauRisk` y riesgo de sobrecarga.
    - Sugerencia de `PredictiveAdjustment` compatibles con las reglas de negocio del plan.

- **Integraciones clave**
  - Con `Entrenadores virtuales personalizados`:
    - Sugiere rediseños parciales del plan (mesociclos, microciclos).
  - Con `Gamificación adaptativa`:
    - Construye retos y misiones alineados con las proyecciones de rendimiento.

- **Monetización asociada**
  - “Coach avanzado” como funcionalidad premium, con proyecciones, escenarios “what-if” y recomendaciones de cambio de estrategia.

---

### 9. Integración con dispositivos de fitness

**Descripción funcional**  
Integración con wearables y dispositivos para capturar datos de actividad diaria, FC, calorías, etc. y alimentar todos los módulos de IA.

- **Objetivo principal del módulo**
  - Ser la **capa de ingesta y orquestación de datos externos**, asegurando:
    - Sincronización fiable con dispositivos y plataformas (Apple Health, Google Fit, Garmin, etc.).
    - Normalización de métricas y unidades.
    - Gestión segura de permisos y privacidad.

- **Modelo de dominio (macro)**
  - Entidades principales:
    - `ExternalDataSource`: fuente externa (Apple Health, Garmin, Fitbit, etc.).
    - `DeviceLink`: vinculación usuario ↔ dispositivo/plataforma.
    - `ExternalMetric`: métrica normalizada (pasos, calorías, FC promedio, HRV, sueño, etc.).
    - `SyncJob`: trabajo de sincronización (manual, programado, en tiempo real).

- **Checklist de integración**
  - [ ] Definir ecosistema de dispositivos soportados (Apple Watch, Garmin, Fitbit, etc.)
  - [ ] Definir mecanismos de autenticación y permisos de datos
  - [ ] Definir normalización de datos entre proveedores

- **Checklist de arquitectura**
  - [ ] Definir servicios/módulos específicos para ingesta de datos externos
  - [ ] Definir mecanismos de resiliencia (reintentos, colas, reconciliación)

- **Diseño técnico**
  - Integraciones:
    - Uso de APIs oficiales (HealthKit, Google Fit, Fitbit, Garmin Connect, etc.).
    - Modelado de webhooks o pulls periódicos según limitaciones de cada proveedor.
  - Consideraciones:
    - Throttling/rate limits, colas para ingesta asíncrona, reconciliación de duplicados.
    - Mapeo consistente de métricas a `WorkoutMetric`, `SleepSession`, `RecoveryMetric`, etc.

- **Integraciones clave**
  - Alimenta:
    - `Seguimiento de progreso inteligente`, `Monitoreo de sueño y recuperación`, `Entrenamiento predictivo`, `Nutrición inteligente`.

- **Monetización asociada**
  - Integraciones básicas gratuitas, conectores avanzados (más granularidad, más histórico) en planes de pago.

---

### 10. Feedback motivacional personalizado

**Descripción funcional**  
Mensajes motivacionales adaptados al estado emocional y contexto del usuario, manteniendo el compromiso con la rutina.

- **Objetivo principal del módulo**
  - Actuar como la **capa emocional** del sistema:
    - Traducir datos fríos (métricas) en mensajes motivacionales humanos.
    - Ajustar tono, frecuencia y contenido al perfil psicológico y contexto del usuario.

- **Modelo de dominio (macro)**
  - Entidades principales:
    - `MotivationProfile`: preferencias de estilo de motivación (directo, suave, competitivo, inspirador).
    - `MotivationEvent`: evento que dispara un mensaje (hito, caída de rendimiento, racha, retorno tras pausa, etc.).
    - `MotivationMessage`: mensaje concreto (texto/voz) con metadata (tono, intensidad, canal).
    - `MotivationHistory`: histórico de mensajes enviados y respuesta del usuario (interacción, adherencia posterior).

- **Checklist funcional**
  - [ ] Definir tipos de mensajes (refuerzo positivo, recordatorios, empatía, celebración)
  - [ ] Definir momentos clave para enviar mensajes (antes/después de entrenar, rachas, caídas)

- **Checklist de IA**
  - [ ] Definir señales para inferir estado del usuario (actividad reciente, drop en rendimiento, etc.)
  - [ ] Definir modelos/reglas para seleccionar el tipo de mensaje adecuado

- **Diseño de IA**
  - Señales:
    - Frecuencia de entrenos, variación de rendimiento, rachas, abandono, logs de estado de ánimo (si existen).
  - Decisiones:
    - Tipo de mensaje (celebración, apoyo, empuje, reactivación).
    - Momento del envío (durante entreno, post-entreno, días de descanso).
    - Canal (notificación push, mensaje in-app, voz si está en sesión guiada).
  - Aprendizaje:
    - Usar `MotivationHistory` para aprender qué tipo de mensajes generan mejor adherencia en cada usuario.

- **Integraciones clave**
  - Con `Gamificación adaptativa`: acompaña logros, retos superados y fracasos con feedback adecuado.
  - Con `Asistente de entrenamiento en tiempo real`: mensajes de motivación durante la sesión.
  - Con `Entrenamiento predictivo`: avisos cuando se prevé estancamiento o cuando se alcanzan hitos proyectados.

- **Monetización asociada**
  - Packs de “entrenadores virtuales” con voces y estilos distintos como parte de planes premium.
  - Personalización avanzada del tono y contenido para suscriptores de nivel superior.

---

## Arquitectura técnica macro

### Decisiones arquitectónicas base
- [ ] Definir estilo arquitectónico (Clean / Hexagonal / Event-driven, etc.)
- [ ] Definir estándares transversales (logging, monitorización, trazas, seguridad, testing)
- [ ] Definir políticas de versionado, branching, CI/CD y entornos (dev, staging, prod)

### Capas y responsabilidad
- [ ] Describir capas principales (presentación, dominio, datos, infraestructura)
- [ ] Definir contratos entre capas (interfaces, DTOs, eventos)
- [ ] Definir patrón de comunicación entre servicios (REST, gRPC, colas, etc.)

---

## Roadmap por fases (versión macro)

> Cada fase se irá completando con el detalle que me vayas compartiendo. Aquí solo fijamos la estructura general.

### Fase 0 – Fundaciones y alineación

- **Checklist conceptual**
  - [ ] Alinear visión de negocio y producto
  - [ ] Definir mapa de dominios y contexto
  - [ ] Identificar riesgos clave (técnicos, de negocio, regulatorios)
  - [ ] Definir principios arquitectónicos y estándares de código

- **Checklist técnica**
  - [ ] Definir stack tecnológico (frontend, backend, IA, data, infra)
  - [ ] Definir estrategia de autenticación/autorización
  - [ ] Definir estrategia de datos (modelo conceptual, compliance, privacidad)
  - [ ] Definir pipeline de CI/CD y flujos de release

---

### Fase 1 – Arquitectura base e infraestructuras

- **Checklist de infraestructura**
  - [ ] Definir entornos (dev / staging / prod) y su configuración
  - [ ] Definir observabilidad (logs, métricas, alertas)
  - [ ] Configurar seguridad base (secrets, roles, accesos, cifrado)

- **Checklist de servicios base**
  - [ ] Definir servicios core (auth, user profile, configuración)
  - [ ] Documentar contratos de APIs internas
  - [ ] Definir y documentar modelo de datos inicial

---

### Fase 2 – Dominios núcleo de negocio

- **Checklist de diseño de dominio**
  - [ ] Modelar entidades principales de negocio
  - [ ] Definir casos de uso / application services
  - [ ] Definir políticas de validación y reglas de negocio

- **Checklist de implementación**
  - [ ] Implementar casos de uso prioritarios
  - [ ] Implementar repositorios y adaptadores a infraestructura
  - [ ] Cubrir con tests unitarios y de integración los flujos críticos

---

### Fase 3 – IA, personalización y automatizaciones

- **Checklist de datos e IA**
  - [ ] Definir fuentes de datos para entrenamiento y evaluación
  - [ ] Definir arquitectura de datos (pipelines, almacenamiento, calidad)
  - [ ] Definir estrategia de entrenamiento, despliegue y monitorización de modelos

- **Checklist de integración IA ↔ producto**
  - [ ] Diseñar interfaces entre modelos/servicios de IA y el backend principal
  - [ ] Definir métricas de calidad de recomendaciones/decisiones
  - [ ] Implementar flujos de fallback cuando la IA falle o no tenga confianza suficiente

---

### Fase 4 – Experiencia de usuario y capas de interacción

- **Checklist de UX/UI**
  - [ ] Definir journeys completos de usuario (onboarding, día a día, soporte, etc.)
  - [ ] Definir diseño de interacción y patrones de UI
  - [ ] Definir guidelines de accesibilidad y rendimiento

- **Checklist de integración front ↔ backend**
  - [ ] Definir contratos API alineados con los flujos de UX
  - [ ] Optimizar payloads, paginación, cache y estados
  - [ ] Definir métricas de rendimiento (TTI, TTFB, latencias clave)

---

### Fase 5 – Observabilidad de negocio, analítica y growth

- **Checklist de analítica**
  - [ ] Definir eventos de tracking de producto
  - [ ] Definir cuadros de mando (retención, engagement, conversión, etc.)
  - [ ] Integrar herramientas de analítica y experimentación (A/B testing)

- **Checklist de growth y optimización**
  - [ ] Definir loops de feedback usuario → producto → equipo
  - [ ] Establecer cadencia de revisión de métricas y decisiones
  - [ ] Definir estrategia de experimentación continua

---

## Riesgos, dependencias y decisiones clave

- **Riesgos principales**
  - [ ] Identificar riesgos técnicos y su impacto
  - [ ] Identificar riesgos de negocio/market fit
  - [ ] Definir planes de mitigación

- **Dependencias**
  - [ ] Listar dependencias internas (entre dominios y servicios)
  - [ ] Listar dependencias externas (proveedores, APIs, infra)
  - [ ] Definir planes de contingencia

- **Registro de decisiones arquitectónicas (ADR)**
  - [ ] Crear formato estándar de ADR
  - [ ] Registrar decisiones críticas (stack, patrones, proveedores)
  - [ ] Mantener histórico y revisiones

---

## Backlog maestro y checklist global

### Backlog alto nivel
- [ ] Completar definición de visión y dominios
- [ ] Completar diseño macro de arquitectura
- [ ] Completar definición de roadmap por fases

### Checklist de calidad y gobernanza
- [ ] Definir estándares de código y revisiones (code review, linters, formato)
- [ ] Definir estrategia de testing (unitario, integración, e2e, carga)
- [ ] Definir estrategia de documentación (técnica, producto, arquitectura)

---

## Notas de trabajo y próximos pasos

En esta sección iremos añadiendo puntos concretos a medida que me pases más detalles:
- [ ] Integrar la información de negocio que compartas en la sección de **Visión general**
- [ ] Mapear funcionalidades concretas a cada fase del **Roadmap por fases**
- [ ] Ajustar checklists para que reflejen exactamente el alcance real del ecosistema

---

## Flujo completo de la aplicación (vista implementación Flutter + Firebase + IA)

> Esta sección conecta el journey funcional con tecnologías concretas (Flutter, Firebase, servicios de IA) sin repetir la lógica de negocio, sino indicando **qué se usa y dónde**.

### 1. Pantalla de bienvenida / Landing

- **Objetivo**: captar atención y lanzar onboarding.
- **Contenido**:
  - Logo, mensaje de valor, CTA “Comenzar” / “Iniciar sesión”.
  - Acceso a términos y privacidad.
  - Opcional: carrusel de features (IA, gamificación, retos, nutrición, etc.).
- **Stack / Integraciones**:
  - Flutter (UI, animaciones; opcionalmente FlutterFlow para prototipado).
  - Firebase Analytics: eventos de impresión, clic en CTA, abandono.

### 2. Registro / Inicio de sesión

- **Objetivo**: autenticación y creación de cuenta.
- **Flujo**:
  - Registro/login con:
    - Email/contraseña.
    - Google / Apple / Facebook (OAuth).
  - Recuperar contraseña.
  - Preguntar (opcional) si desea ya vincular Google Fit / Apple Health.
- **Stack / Integraciones**:
  - Firebase Authentication (email + proveedores OAuth).
  - Firebase Analytics (eventos de sign_up, login, error).

### 3. Configuración de perfil (Onboarding de usuario)

- **Objetivo**: recopilar datos para personalización (entreno, nutrición, IA).
- **Datos**:
  - Físicos: edad, sexo, peso, altura.
  - Nivel: principiante / intermedio / avanzado.
  - Objetivos: pérdida de peso, fuerza, resistencia, tonificación, salud general.
  - Limitaciones: lesiones, restricciones.
  - Preferencias de ejercicios: cardio, fuerza, HIIT, yoga, etc.
  - Horarios y frecuencia.
  - Preferencias de notificaciones y gamificación.
- **Stack / Integraciones**:
  - Firebase Firestore: persistencia de perfil.
  - Servicio de IA (OpenAI, etc.): sugerencias iniciales de plan (opcional, server-side).

### 4. Dashboard / Pantalla principal

- **Objetivo**: vista de control diaria.
- **Secciones**:
  - Resumen de entrenos recientes.
  - Estadísticas clave (tiempo, calorías, % objetivo semanal).
  - Próximo entrenamiento.
  - Accesos rápidos a:
    - Entrenamientos personalizados.
    - Desafíos / competiciones.
    - Gamificación / logros.
    - Nutrición y recuperación.
- **Stack / Integraciones**:
  - Flutter: UI + gráficos (charts).
  - Firestore: datos de progreso en tiempo (casi) real.
  - IA (OpenAI u otra): mensajes motivacionales contextuales.

### 5. Entrenamientos personalizados (core entrenador virtual)

- **Objetivo**: ejecutar el plan adaptado a cada usuario.
- **Funcionalidades**:
  - Planes generados dinámicamente según perfil + progreso.
  - Ajustes de duración, intensidad, ejercicios.
  - Feedback en tiempo real (voz/texto).
  - Registro de resultados (reps, tiempos, pesos, RPE).
- **Stack / Integraciones**:
  - IA (OpenAI / modelos propios):
    - Generación de estructuras de entreno (server-side).
    - Mensajes de feedback y motivación.
  - TensorFlow / Google Cloud AI:
    - Modelos predictivos de rendimiento y adaptación del plan.
  - Firestore:
    - Guardar sesiones, performance, feedback.
  - MediaPipe / OpenPose (opcional):
    - Análisis de técnica si se usa cámara.

### 6. Entrenamientos grupales virtuales

- **Objetivo**: componente social y de comunidad.
- **Funcionalidades**:
  - Sesiones en vivo (con instructor humano o virtual).
  - Chat en tiempo real, reacciones.
  - Rankings de participación y rendimiento.
- **Stack / Integraciones**:
  - Firebase Realtime Database o Firestore (streams en tiempo real).
  - WebRTC / plugins de vídeo en Flutter para sesiones en vivo.
  - IA (OpenAI):
    - Asistente virtual del grupo (mensajes motivacionales, recordatorios).

### 7. Gamificación y desafíos

- **Objetivo**: aumentar adherencia con mecánicas de juego.
- **Funcionalidades**:
  - Sistema de puntos, niveles, medallas, trofeos.
  - Desafíos diarios/semanales/mensuales (individuales y grupales).
  - Rankings (globales y entre amigos).
  - Desafíos adaptativos según rendimiento.
- **Stack / Integraciones**:
  - Firestore: puntos, logros, retos activos.
  - IA:
    - OpenAI para descripción narrativa de retos y mensajes.
    - TensorFlow / ML para ajustar dificultad según datos del usuario.

### 8. Estadísticas y análisis predictivo

- **Objetivo**: ofrecer insight y predicciones accionables.
- **Funcionalidades**:
  - Métricas: tiempo de entreno, calorías, repeticiones, cargas, IMC aproximado, etc.
  - Gráficos de tendencias (semanal, mensual, anual).
  - Predicciones de rendimiento y estimación de fechas para metas.
  - Comparación con usuarios similares (anonimizada).
- **Stack / Integraciones**:
  - Firestore: histórico de sesiones, métricas agregadas.
  - TensorFlow / Google Cloud AI:
    - Modelos de series temporales y predicciones.
  - IA (OpenAI):
    - Explicación de estadísticas en lenguaje natural y recomendaciones.

### 9. Nutrición y recuperación

- **Objetivo**: completar el ecosistema más allá del entreno.
- **Funcionalidades**:
  - Planes de alimentación personalizados.
  - Registro de comidas (manual / escaneo / texto libre).
  - Recomendaciones de sueño y recuperación según carga y datos de dispositivos.
- **Stack / Integraciones**:
  - Firestore: almacenamiento de planes y logs de comidas.
  - Google Fit / Apple Health:
    - Datos de sueño, actividad diaria.
  - IA (OpenAI + ML propio):
    - Generación/ajuste de planes nutricionales.
    - Consejos de recuperación personalizados.

### 10. Soporte automatizado (asistente in-app)

- **Objetivo**: reducir soporte humano mediante IA conversacional.
- **Funcionalidades**:
  - Chat de ayuda dentro de la app.
  - FAQ dinámicas (entrenos, retos, pagos, dispositivos).
  - Sugerencias de uso de nuevas features.
- **Stack / Integraciones**:
  - IA (OpenAI / similar):
    - Asistente conversacional con contexto de producto.
  - Firestore:
    - Historial de consultas para análisis y mejora.

### 11. Notificaciones y retención

- **Objetivo**: mantener al usuario activo y motivado.
- **Funcionalidades**:
  - Recordatorios de entrenos, retos y metas.
  - Alertas de logros (“nuevo PR”, “racha X días”).
  - Mensajes motivacionales personalizados según actividad reciente.
- **Stack / Integraciones**:
  - Firebase Cloud Messaging (FCM): push notifications.
  - IA (OpenAI):
    - Generación del contenido de los mensajes (tono, contexto).
  - Firebase Analytics:
    - Medición de apertura y efectividad de notificaciones.

### 12. Monetización

- **Modelo**:
  - Freemium:
    - Básico gratis (planes estándar, métricas simples).
  - Suscripción Premium:
    - Entrenamientos avanzados, analítica predictiva, IA personalizada, retos especiales, nutrición avanzada.
  - Opcionales:
    - Publicidad in-app (con cuidado de no afectar UX).
    - Programas de afiliados (material deportivo, suplementos).
    - Consultorías con entrenadores humanos.
- **Stack / Integraciones**:
  - Google Play Billing / App Store IAP.
  - Firebase Analytics:
    - Funnels de conversión, churn, LTV.

---

## Mapa de pantallas y navegación (Flutter + GoRouter)

### Áreas principales

- **Auth + Onboarding (antes del main app)**
  - `SplashScreen`
  - `WelcomeScreen`
  - `LoginScreen`
  - `RegisterScreen`
  - `OnboardingProfileWizard` (varias subpantallas)
  - `DeviceLinkScreen`

- **Main App (post login, con bottom navigation)**
  - `HomeDashboardScreen`
  - Zona entrenamiento (`TrainingPlanScreen`, `WorkoutDetailScreen`, `WorkoutSessionScreen`, `WorkoutSummaryScreen`, `FreeWorkoutBuilderScreen`)
  - Zona progreso (`ProgressOverviewScreen`, `ProgressDetailsScreen`)
  - Zona nutrición & recuperación (`NutritionDashboardScreen`, `NutritionPlanScreen`, `FoodLogScreen`, `RecoveryDashboardScreen`)
  - Zona comunidad & retos (`ChallengesHomeScreen`, `ChallengeDetailScreen`, `GroupWorkoutLobbyScreen`, `GroupWorkoutLiveScreen`)

- **Global**
  - `SupportChatScreen`
  - `SettingsScreen`
  - `SubscriptionScreen`

### Esquema de rutas (GoRouter, propuesta)

```text
/                      -> SplashScreen
/welcome               -> WelcomeScreen
/auth/login            -> LoginScreen
/auth/register         -> RegisterScreen
/onboarding/...        -> Onboarding*Screens
/devices               -> DeviceLinkScreen

/app                   -> HomeLayout (shell con bottom nav)
/app/home              -> HomeDashboardScreen
/app/training          -> TrainingPlanScreen
/app/training/workout/:id          -> WorkoutDetailScreen
/app/training/session/:id          -> WorkoutSessionScreen
/app/training/summary/:sessionId   -> WorkoutSummaryScreen

/app/progress                      -> ProgressOverviewScreen
/app/progress/:metricId            -> ProgressDetailsScreen

/app/recovery/nutrition            -> NutritionDashboardScreen
/app/recovery/nutrition/plan       -> NutritionPlanScreen
/app/recovery/nutrition/log        -> FoodLogScreen
/app/recovery                      -> RecoveryDashboardScreen

/app/community/challenges          -> ChallengesHomeScreen
/app/community/challenges/:id      -> ChallengeDetailScreen
/app/community/group/:id/lobby     -> GroupWorkoutLobbyScreen
/app/community/group/:id/live      -> GroupWorkoutLiveScreen

/app/support                       -> SupportChatScreen
/app/settings                      -> SettingsScreen
/app/subscription                  -> SubscriptionScreen
```

---

## Backlog inicial de implementación (por fases)

### Fase 0 – Fundaciones

- **Infraestructura y arquitectura**
  - Configurar proyecto Flutter y estructura de capas (presentación, dominio, datos).
  - Integrar Firebase (Auth, Firestore, Analytics, FCM).
  - Definir modelos base: `UserProfile`, `TrainingPlan`, `TrainingSession`, `WorkoutPerformance`.

- **Auth + Onboarding mínimo**
  - Historias:
    - Como usuario, quiero registrarme/iniciar sesión con email y Google.
    - Como usuario nuevo, quiero completar un onboarding básico con datos físicos + objetivos + nivel.
  - Pantallas:
    - `SplashScreen`, `WelcomeScreen`, `LoginScreen`, `RegisterScreen`,
      `OnboardingBasicsScreen`, `OnboardingGoalsScreen`.

### Fase 1 – Núcleo de entrenamiento y Home

- **Home + entreno individual**
  - Historias:
    - Como usuario, quiero ver mi próximo entrenamiento en el dashboard.
    - Como usuario, quiero ver mi plan semanal de entrenos.
    - Como usuario, quiero iniciar una sesión guiada y registrar mis resultados.
  - Implementar:
    - `HomeDashboardScreen`.
    - `TrainingPlanScreen`, `WorkoutDetailScreen`,
      `WorkoutSessionScreen`, `WorkoutSummaryScreen`.
    - Persistencia de resultados en Firestore.

- **IA básica de planes (reglas)**
  - Definir un motor de reglas determinísticas para generar el primer plan en base al perfil,
    preparando el backend para introducir modelos ML más adelante.

### Fase 2 – Progreso y gamificación básica

- **Progreso**
  - Historias:
    - Como usuario, quiero ver mis estadísticas básicas (tiempo total, sesiones por semana, volumen).
  - Implementar:
    - `ProgressOverviewScreen` con primeras gráficas conectadas a Firestore.

- **Gamificación simple**
  - Historias:
    - Como usuario, quiero ganar puntos por completar entrenos y ver mis logros básicos.
  - Implementar:
    - Modelo de puntos por sesión.
    - Colección de logros simple en Firestore.

### Fase 3 – IA, nutrición y recuperación

- **IA v1 (adaptación de plan)**
  - Entrenar modelos sencillos (TensorFlow / Cloud AI) para:
    - Ajustar el plan semanal según adherencia y carga.
  - Integrar app → backend → app para recibir y aplicar ajustes.

- **Nutrición y recuperación**
  - Historias:
    - Como usuario, quiero ver un plan nutricional básico alineado con mi objetivo.
    - Como usuario, quiero ver un indicador de mi estado de recuperación.
  - Implementar:
    - `NutritionDashboardScreen`, `NutritionPlanScreen`, `RecoveryDashboardScreen`.
    - Integración inicial con Google Fit / Apple Health para sueño/actividad.

### Fase 4 – Comunidad, IA conversacional y CV

- **Comunidad y retos**
  - Historias:
    - Como usuario, quiero unirme a retos y ver rankings.
    - Como usuario, quiero participar en entrenos grupales en vivo.
  - Implementar:
    - `ChallengesHomeScreen`, `ChallengeDetailScreen`,
      `GroupWorkoutLobbyScreen`, `GroupWorkoutLiveScreen`.

- **Soporte IA + asistente**
  - Implementar `SupportChatScreen` con IA (OpenAI) para FAQs y ayuda contextual.

- **Visión por computador (proto)**
  - Prototipo de análisis de técnica con MediaPipe/OpenPose para un subconjunto de ejercicios.

---

## Extensión SaaS para boxes y centros de entrenamiento (WodMaster / WodVerse)

### Visión del ecosistema unificado

- **Producto B2C**: App de atletas (IAEntrenar App)
  - Entrenamientos personalizados con IA, nutrición, recuperación, progreso, gamificación y comunidad social.
- **Producto B2B**: SaaS para boxes/centros (WodMaster Pro / WodVerse Admin)
  - Gestión de clases, reservas, pagos, coaches y analítica.
- **Plataforma global (WodVerse)**:
  - Conecta atletas, boxes, coaches y marcas en un único ecosistema.
  - Comparte núcleo de datos (Firebase) e IA (OpenAI + TensorFlow).

### Dominios adicionales para el SaaS

- `Tenant` (Box / Centro)
  - Representa un box, gimnasio o entrenador con su propio espacio lógico.
  - Atributos: nombre, logo, ubicación, branding, plan de suscripción, settings.
- `Class`
  - Clases programadas (CrossFit, HIIT, fuerza, movilidad, etc.).
  - Atributos: fecha/hora, duración, tipo, coach asignado, capacidad, nivel.
- `Reservation`
  - Reserva de un atleta para una clase concreta.
  - Atributos: userId, classId, estado (confirmada, lista espera, cancelada), timestamps.
- `Membership`
  - Relación atleta ↔ box (tipo de membresía, validez, cuotas, estado).
- `Payment`
  - Pagos de atletas al box y de boxes a la plataforma.
- `WodTemplate`
  - Plantillas de WODs que pueden publicarse en el box y vincularse a sesiones.

---

## Modelo de roles y multi-tenant

### Roles principales

- `super_admin`
  - Control global de la plataforma: todos los tenants, planes, facturación.
- `platform_billing`
  - Acceso a métricas y cobros globales, sin modificar lógica de negocio.
- `tenant_admin` (box_admin)
  - Admin de un box: clases, coaches, pagos, miembros, branding.
- `coach`
  - Gestión de sus clases y atletas: crea WODs, revisa resultados, interactúa.
- `frontdesk`
  - Check-in, reservas, control de aforo, cobros en recepción.
- `athlete`
  - Usuario final: reservas, WODs, progreso, comunidad, premium.
- `support`
  - Soporte técnico con acceso limitado a datos para resolución de incidencias.

### Estrategia de autorización

- Autenticación: **Firebase Auth** (email/password, Google, Apple, etc.).
- Autorización: **custom claims** en el token de Firebase:
  - `role`: rol principal del usuario (p.ej. "tenant_admin").
  - `tenantId`: identificador del box/gimnasio cuando aplica.
- Reglas de Firestore:
  - Permiten acceso a documentos sólo si `request.auth.token.tenantId` coincide con el `tenantId` del recurso, excepto para `super_admin`.

---

## Modelo de datos Firestore (visión resumida)

- `/tenants/{tenantId}`
  - Metadata del box (nombre, logo, ubicación, plan, settings).
  - Subcolecciones:
    - `/classes/{classId}`
    - `/members/{memberId}`
    - `/payments/{paymentId}`
    - `/coaches/{coachId}`
    - `/wods/{wodId}`
- `/users/{uid}`
  - Perfil global del usuario:
    - Datos básicos, rol, `tenantId` (si aplica), perfil de atleta, flags premium.
- `/reservations/{reservationId}`
  - Reserva con referencia a `classId`, `tenantId` y `userId`.
- `/workouts/{workoutId}` y `/results/{resultId}`
  - Plantillas de entreno y resultados individuales.
- `/feed/{postId}`
  - Publicaciones de la comunidad (con `tenantId` opcional para posts de box).
- `/payments/{paymentId}`
  - Registro global de pagos (enlace a Stripe/PayPal).

---

## Flujo funcional del SaaS de agendamiento

### 1. Onboarding de box / centro (tenant)

- Dueño crea cuenta (o es invitado por `super_admin`).
- Completa:
  - Datos del box, horarios generales, tipos de clases, métodos de pago.
- `super_admin` o backend:
  - Asigna `role = tenant_admin` y `tenantId` vía Cloud Function.

### 2. Alta de coaches y staff

- `tenant_admin` invita a coaches/frontdesk:
  - Envía enlaces de invitación.
  - Al registrarse, Cloud Function asigna `role` y `tenantId`.
- Coaches acceden:
  - A sus clases, WODs, listas de atletas y mensajes.

### 3. Gestión de clases y horarios

- `tenant_admin` o `coach`:
  - Crea clases (`Class`): tipo, hora, capacidad, nivel, coach asignado.
  - Configura reglas de reservas, cancelaciones, lista de espera.
- El calendario del box se expone:
  - En el **panel web** para staff.
  - En la **app de atletas** filtrado por `tenantId`.

### 4. Reservas desde la app de atleta

- Atleta autenticado:
  - Ve el calendario de su box (`tenantId`).
  - Reserva clases con un toque; si está lleno, entra en lista de espera.
- Cloud Function:
  - Valida capacidad y estado.
  - Crea `Reservation` y envía notificaciones (push/email).

### 5. Check-in y asistencia

- Frontdesk o coach:
  - Usa la app/panel para hacer check-in:
    - Vía lista manual, QR o NFC.
  - Marca asistencia, ausencias y cancelaciones tardías.
- Los datos de asistencia:
  - Alimentan métricas de retención, ocupación y progreso.

### 6. Pagos y membresías

- Integración con Stripe / PayPal:
  - Suscripciones mensuales, bonos de clases o pago por uso.
- Cloud Functions:
  - Gestionan webhooks de pagos, renovación y cancelaciones.
- La plataforma:
  - Calcula ingresos del box, comisiones, y muestra reportes.

### 7. Analítica y IA para el box

- Dashboards:
  - Asistencia por clase, ocupación, horarios fuertes/débiles, retención.
- IA:
  - Predice demanda por franja horaria.
  - Sugiére ajustes de horarios y clases.
  - Señala usuarios en riesgo de abandono para activar campañas de retención.

---

## Encaje con la app de atletas (IAEntrenar)

- Reservas y entrenos:
  - Las clases reservadas en el SaaS se sincronizan con el historial de entrenos del atleta.
- IA de entrenamiento:
  - Tiene en cuenta las clases reservadas y realizadas para:
    - Ajustar volumen total semanal.
    - Modificar entrenamientos individuales fuera del box.
- Comunidad y feed:
  - Los WODs y logros del box se pueden publicar en el feed de la app.
- Premium atleta:
  - Funcionalidades extra como:
    - IA avanzada de análisis corporal y progreso.
    - Analítica detallada de rendimiento.
    - Retos especiales y contenido exclusivo.

---

## Proyecto global: WodVerse (visión consolidada)

- **WodVerse** como paraguas de marca:
  - App de atletas (IAEntrenar).
  - SaaS para boxes (WodMaster Pro / WodVerse Admin).
  - Módulos de IA (WodAI), comunidad (WodSocial), marketplace (WodMarket) y analítica (WodAnalytics).
- **Objetivo**:
  - Ser la plataforma de referencia para:
    - Gestión de boxes y entrenadores.
    - Experiencia de atleta gamificada y personalizada.
    - Análisis de datos y recomendaciones impulsadas por IA.

---

## Especificación extendida de roles, permisos y multi-tenant

### Definición de `Tenant`

- Un `Tenant` representa un **cliente B2B** del ecosistema (box de CrossFit, centro de entrenamiento, gimnasio, estudio, franquicia, etc.).
- Cada tenant tiene:
  - Sus propias clases, reservas, WODs, miembros, pagos, reportes, integraciones y branding.
  - Un aislamiento lógico de datos respecto a otros tenants dentro de la misma plataforma.
- Ejemplos de `tenantId`:
  - `box_madrid_alpha`, `crossfit_valencia_centro`, `elite_training_sevilla`.

### Modelo de tenancy recomendado

- **En Firestore**:
  - `/tenants/{tenantId}/...` contiene todos los datos específicos del box:
    - `settings`, `classes`, `reservations`, `members`, `coaches`, `wods`, `results`, `billing`, `analytics`, `logs`, `invites`.
  - Colecciones globales:
    - `/users/{uid}`: perfil global.
    - `/tenants_meta/{tenantId}`: info pública y de discovery.
    - `/audit/{logId}`: auditoría global.
    - `/marketplace/{productId}`: catálogo de productos/planes.
- **Aislamiento**:
  - Todas las operaciones sensibles se validan con:
    - `request.auth.token.tenantId == tenantId` (en reglas Firestore).
  - Excepción: roles globales (`super_admin`, `platform_billing`, `platform_ops`).

### Roles globales y por tenant

- **Globales**:
  - `super_admin`: acceso total a todos los tenants, billing, features, auditoría e impersonación.
  - `platform_billing`: gestión financiera global (conciliación, reembolsos, planes).
  - `platform_ops`: operaciones técnicas, despliegues, observabilidad.
  - `auditor`: solo lectura de logs/auditoría.
- **Por tenant**:
  - `tenant_admin` / `box_admin`:
    - Administra box completo: clases, coaches, miembros, facturación del tenant, integraciones, branding.
  - `manager` (opcional):
    - Subadmin con permisos intermedios (sin full billing).
  - `coach`:
    - Gestiona WODs, clases propias, resultados y feedback a atletas.
  - `frontdesk`:
    - Check-in, ventas presenciales, reservas locales, listas de espera.
  - `support_tenant`:
    - Soporte interno del box (tickets, incidencias).
  - `athlete`:
    - Usuario final: reservas, resultados, estadísticas, social, premium.
  - `readonly_guest`:
    - Acceso limitado a información pública (landing, horarios públicos, eventos).

### Custom claims y autenticación

- Cada usuario autenticado con Firebase Auth lleva en su token:
  - `role`: rol principal.
  - `tenantId`: identificador del box (nullable para roles globales o atletas independientes).
  - Otros posibles: `org`, `resellerId`.
- Ejemplo:
  - `{ "sub": "uid_abc123", "role": "coach", "tenantId": "box_madrid_alpha" }`
- Las aplicaciones cliente (Flutter/web) deben:
  - Leer `idTokenResult` al iniciar sesión.
  - Guardar `role` y `tenantId` en su capa de estado (p.ej. `AuthProvider`).
  - Restringir rutas y vistas en función de estos valores (además de las reglas backend).

### Matriz de permisos (resumen)

- **Ejemplos clave**:
  - Crear/editar clases:
    - `super_admin`: sí, en cualquier tenant.
    - `tenant_admin`, `coach`, `frontdesk`: sí, sólo si `auth.tenantId == tenantId`.
  - Gestionar facturación de un box:
    - `super_admin`, `platform_billing`, `tenant_admin` (solo su tenant).
  - Crear tenant:
    - Sólo `super_admin`.
  - Reservar clases:
    - `athlete`, `coach`, `frontdesk`, `tenant_admin` dentro de su tenant.
  - Impersonar usuario:
    - Solo `super_admin`/`platform_ops`, siempre registrado en auditoría.

### Reglas de seguridad Firestore (esqueleto)

- Reglas base:
  - `/users/{userId}`:
    - Lectura: cualquier usuario autenticado.
    - Escritura: sólo el propio user (`uid == userId`).
  - `/tenants/{tenantId}/{document=**}`:

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    match /tenants/{tenantId}/{docPath=**} {
      function isAuth() { return request.auth != null; }
      function isSuperAdmin() {
        return isAuth() && request.auth.token.role == 'super_admin';
      }
      function inSameTenant() {
        return isAuth() && request.auth.token.tenantId == tenantId;
      }

      allow read: if isAuth() && (isSuperAdmin() || inSameTenant());

      allow create, update, delete: if isAuth() && (
        isSuperAdmin() ||
        (inSameTenant() &&
          request.auth.token.role in ['tenant_admin','coach','frontdesk'])
      );
    }
  }
}
```

### Cloud Functions críticas

- `createTenant(payload)`:
  - Crea tenant, provisiona Stripe, crea invitación para `tenant_admin`.
- `assignRole({uid, role, tenantId})`:
  - Asigna `customClaims` y persiste en Firestore; escribe log en `/audit`.
- `createReservation({classId, userId})`:
  - Operación transaccional: verifica capacidad, crea reserva, envía notificaciones.
- `refundPayment({paymentId, reason})`:
  - Integra con Stripe, actualiza transacciones, audit.
- `createImpersonationToken({targetUid, ttl})`:
  - Emite token temporal de impersonación para soporte/super_admin.
- `aiGenerateWorkout({userId, params})`, `aiVideoAnalysis(...)`:
  - Llaman a servicios de IA (OpenAI/TensorFlow) y guardan resultados.
- `exportUserData({uid})` y `deleteUserData({uid})`:
  - Cumplimiento GDPR (export / borrado).

### Auditoría, logging y cumplimiento

- Toda acción privilegiada (roles, pagos, impersonación, cambios de plan) debe:
  - Escribir entrada en `/audit/{logId}` o `/tenants/{tenantId}/logs/{logId}`:
    - `actorUid`, `actorRole`, `action`, `targetType`, `targetId`, `tenantId`, `meta`, `ip`, `userAgent`, `timestamp`.
- Logs:
  - Son inmutables (no se borran, sólo se archivan si es necesario).
  - Pueden exportarse a BigQuery para BI / análisis forense.
- GDPR:
  - Registro de consentimientos.
  - Endpoints de export y borrado.
  - Políticas de retención de datos (p.ej. logs 2 años, datos de usuario 6–12 meses tras baja).

### Checklist de implementación infra (MVP multi-tenant)

- [ ] Definir esquema Firestore completo para `/tenants/{tenantId}/...` y colecciones globales.
- [ ] Implementar `assignRole` y `createTenant` en Cloud Functions.
- [ ] Configurar reglas de seguridad Firestore en emulator y probar roles/tenants.
- [ ] Implementar `AuthProvider` en Flutter que exponga `user`, `role`, `tenantId`.
- [ ] Implementar guards de rutas en GoRouter según rol/tenant.
- [ ] Implementar `createReservation` con transacciones y tests.
- [ ] Integrar Stripe para suscripciones de tenants y pagos de miembros.
- [ ] Añadir auditoría en todas las funciones críticas.
- [ ] Configurar backups automáticos (Firestore export) y plan de recuperación.

---

## Plan maestro de implementación y tareas (macro, no MVP)

> Este apartado define la **hoja de ruta completa** para construir el ecosistema WodVerse/IAEntrenar: tareas, subtareas, dependencias y entregables. Está pensado para un proyecto **macro**, no una versión reducida.

### 1. Fundaciones estratégicas y de producto

- **1.1. Alineación de visión y alcance**
  - [ ] Definir statement de visión y misión del ecosistema (IAEntrenar + WodVerse).
  - [ ] Definir segmentos de cliente:
    - Atletas independientes.
    - Atletas vinculados a box.
    - Boxes pequeños/medianos.
    - Cadenas/franquicias.
  - [ ] Definir propuestas de valor por segmento (B2C / B2B / B2B2C).
  - [ ] Validar pricing macro (rango de precios, ARPU objetivo).

- **1.2. Roadmap de producto y releases**
  - [ ] Definir releases mayores (v1, v2, v3) y qué incluye cada uno.
  - [ ] Mapear dependencias críticas (auth, billing, reservas, IA).
  - [ ] Definir KPIs de éxito por release (usuarios activos, boxes activos, MRR, retención).

---

### 2. Diseño de dominio y modelo de datos (CRÍTICO)

- **2.1. Modelo de datos canónico**
  - [ ] Documentar esquemas completos para:
    - `Tenant` (`/tenants/{tenantId}`)
    - `User` (`/users/{uid}`)
    - `Member` (`/tenants/{tenantId}/members/{uid}`)
    - `Class` / `Reservation` / `Attendance`
    - `Wod` / `Workout` / `Result`
    - `Payment` / `Invoice` / `Subscription`
    - `FeedPost` / `Comment` / `Challenge`
    - `AiRequest` / `AiAnalysis`
    - `AuditLog`
  - [ ] Crear ejemplos JSON/YAML para cada entidad.
  - [ ] Definir tamaños máximos de documento y estrategias de partición (por fecha, por tenant).

- **2.2. Índices Firestore**
  - [ ] Identificar consultas críticas:
    - Clases por fecha/tenant.
    - Reservas por user/clase.
    - Resultados por user/WOD.
    - Pagos por tenant/fecha.
  - [ ] Definir índices compuestos necesarios.
  - [ ] Documentar `firestore.indexes.json`.

---

### 3. Seguridad, auth y multi-tenant (CRÍTICO)

- **3.1. Autenticación**
  - [ ] Activar proveedores:
    - Email+password.
    - Google.
    - Apple.
  - [ ] Diseñar flujo de signup/login por rol:
    - Atleta.
    - Coach.
    - Tenant_admin.
    - Super_admin / platform_billing (se crean sólo vía backend).
  - [ ] Diseñar e implementar flujo de invitaciones (`invites`):
    - Invitaciones a box (athlete, coach, frontdesk).
    - Tokens con expiración.

- **3.2. Autorización (custom claims)**
  - [ ] Definir formato de claims: `{ role, tenantId, org }`.
  - [ ] Implementar `assignRole` en Cloud Functions:
    - Validar permisos de quien llama.
    - Escribir `customClaims`.
    - Sincronizar con `/tenants/{tenantId}/members/{uid}` y `/users/{uid}`.
  - [ ] Diseñar UX para cambios de rol:
    - Mensaje de “recargar para aplicar cambios”.
    - Refresco automático de token.

- **3.3. Reglas de seguridad Firestore**
  - [ ] Escribir reglas globales para:
    - `/users/{uid}`.
    - `/tenants/{tenantId}/...`.
    - `/audit/{logId}`.
    - Colecciones de billing y AI.
  - [ ] Probar reglas con Emulator:
    - Escenarios: super_admin, tenant_admin, coach, frontdesk, athlete.
    - Escenarios multi-tenant (acceso cruzado denegado).

- **3.4. Multi-tenant isolation**
  - [ ] Confirmar diseño `tenants/{tenantId}/...` como estándar.
  - [ ] Implementar tests automatizados que simulan varios tenants:
    - Usuarios con `tenantId` distintos intentando acceder a datos ajenos.
    - Super_admin accediendo a todos.

---

### 4. Backend crítico (Cloud Functions) (CRÍTICO)

- **4.1. Gestión de tenants**
  - [ ] `createTenant(payload)`:
    - Crear documento `tenants/{tenantId}`.
    - Crear cliente y suscripción en Stripe.
    - Crear invitación inicial para `tenant_admin`.
    - Escribir log de auditoría.
  - [ ] `suspendTenant(tenantId)`:
    - Marcar tenant como suspendido.
    - Pausar suscripciones.
    - Bloquear login a roles de ese tenant (salvo lectura).

- **4.2. Roles y miembros**
  - [ ] `assignRole({uid, role, tenantId})`:
    - Validar que el llamante tiene permisos.
    - Asignar claims y miembro en tenant.
    - Registrar auditoría.
  - [ ] `joinTenantWithInvite(inviteToken)`:
    - Validar invitación, expiración y email (opcional).
    - Crear/actualizar `members/{uid}` y claims.

- **4.3. Reservas y clases**
  - [ ] `createReservation({classId, userId})`:
    - Ejecutar transacción:
      - Leer clase, comprobar capacidad y estado.
      - Crear reserva y actualizar contadores.
    - Encolar notificaciones (FCM/email).
    - Registrar auditoría y analítica.
  - [ ] `cancelReservation({reservationId})`:
    - Gestionar liberación de cupo y lista de espera.
    - Gestionar posibles reembolsos si procede.

- **4.4. Pagos y facturación**
  - [ ] Integrar Stripe (o equivalente) para:
    - Suscripciones de tenants (planes mensuales/anuales).
    - Cobros a atletas (membresías, drop-ins, marketplace).
  - [ ] Cloud Functions:
    - `createPaymentIntent`, `handleStripeWebhook`, `refundPayment`.
  - [ ] Definir:
    - Comisiones de plataforma.
    - Política de reembolsos y disputa.

- **4.5. Operaciones IA**
  - [ ] `aiGenerateWorkout({userId, params})`.
  - [ ] `aiVideoAnalysis({mediaId})`.
  - [ ] `aiWeeklyReport({userId})`.
  - [ ] Implementar:
    - Rate limiting y cuotas por usuario/tenant.
    - Logs de uso en `ai_requests`.

- **4.6. GDPR y compliance**
  - [ ] `exportUserData({uid})`:
    - Agregar todos los documentos relevantes del usuario.
    - Proveer descarga segura (URL firmada).
  - [ ] `deleteUserData({uid})`:
    - Anonimizar datos donde no se pueden borrar (logs, agregados).
    - Borrar datos personales donde sea posible.

---

### 5. Infraestructura, backups y DR (CRÍTICO)

- **5.1. Backups**
  - [ ] Configurar export diario de Firestore a GCS.
  - [ ] Definir retención:
    - Backups diarios 30 días.
    - Backups mensuales 12 meses.
  - [ ] Documentar proceso de restauración.

- **5.2. Disaster Recovery**
  - [ ] Definir RPO/RTO:
    - RPO ≤ 24h, RTO ≤ 24h (ajustable).
  - [ ] Documentar runbook:
    - Pasos para restaurar de backup.
    - Comunicación a clientes.

---

### 6. IA / ML y medios (IMPORTANTE)

- **6.1. Estrategia IA**
  - [ ] Separar claramente:
    - IA generativa (OpenAI) para chat, planes, resúmenes.
    - IA clásica/ML (TensorFlow) para:
      - Predicciones de rendimiento.
      - Análisis de comportamiento (retención, ocupación).
      - Visión por computador (análisis de técnica y composición).
  - [ ] Diseñar arquitectura MLOps mínima:
    - Storage para datasets.
    - Workers para entrenamiento y batch jobs.
    - Monitorización de calidad de modelos.

- **6.2. Media (vídeo/imagen)**
  - [ ] Definir pipeline:
    - Subida a Storage (app).
    - Trigger a Cloud Function (procesamiento).
    - Opcionalmente usar servicios externos (CDN, transcodificación).
  - [ ] Política de:
    - Tamaños máximos.
    - Compresión, formatos soportados.
    - TTL y limpieza automática (para controlar costes).
  - [ ] Consentimiento y privacidad:
    - Flujo de opt-in para análisis de imagen/vídeo.
    - Términos claros de uso de datos.

---

### 7. Frontend: arquitectura Flutter y módulos

- **7.1. Estructura del proyecto Flutter**
  - [ ] Definir estructura de carpetas:
    - `lib/presentation`, `lib/domain`, `lib/data`, `lib/router`, `lib/services`.
  - [ ] Elegir state management:
    - Riverpod / Bloc / Provider (alineado con clean architecture).
  - [ ] Implementar `AuthProvider` / `AuthController`:
    - Cargar `user`, `role`, `tenantId`.
    - Gestionar refresh de tokens.

- **7.2. Navegación (GoRouter)**
  - [ ] Implementar rutas definidas en sección de “Mapa de pantallas”.
  - [ ] Añadir guards:
    - Redirecciones según rol:
      - `super_admin` → panel web.
      - `tenant_admin` / `coach` / `frontdesk` → vistas admin/box.
      - `athlete` → app móvil atleta.
    - Bloqueo si no hay `tenantId` cuando es requerido.

- **7.3. Pantallas por rol (macro)**
  - [ ] Super Admin:
    - Dashboard global.
    - Lista de tenants.
    - Billing global.
    - Auditoría.
  - [ ] Tenant Admin:
    - Dashboard box.
    - Calendario / Clases.
    - Miembros / Coaches.
    - Billing tenant.
    - WOD manager.
    - Reports.
  - [ ] Coach:
    - Agenda de clases.
    - Sesión de clase (live).
    - Gestión de WODs.
    - Roster y perfiles de atletas.
    - Vídeo review con IA.
  - [ ] Frontdesk:
    - Hoy / Check-in.
    - Ventas rápidas.
    - Lista de espera.
  - [ ] Athlete:
    - Onboarding.
    - Home/feed.
    - Discover / booking.
    - WOD player + resultados.
    - Progreso/PRs.
    - Premium (IA, nutrición, analítica).

---

### 8. UX transversal: offline, errores, notificaciones (IMPORTANTE)

- **8.1. Offline & sync**
  - [ ] Decidir qué flujos soportan offline:
    - Registro de resultados.
    - Visualización de histórico.
    - Reservas (opcional, con cuidado).
  - [ ] Implementar almacenamiento local:
    - Hive / Isar / sqlite.
    - Cola de operaciones pendientes.
  - [ ] Estrategia de resolución de conflictos:
    - Última escritura gana (donde no sea crítico).
    - Fusión manual en casos sensibles.

- **8.2. Manejo de errores UX**
  - [ ] Diseñar mensajes claros para:
    - Errores de permisos (`permission-denied`).
    - Fallos de red.
    - Errores de pago.
    - Límite de cuota IA excedido.

- **8.3. Notificaciones y retención**
  - [ ] Definir tipos:
    - Recordatorios de entreno/clases.
    - Notificaciones de logros.
    - Reengagement (IA) para usuarios inactivos.
  - [ ] Implementar:
    - FCM + panel de composición por tenant.
    - Opt-in/out por tipo y horario (no molestar).

---

### 9. Analítica, BI y coste (IMPORTANTE)

- **9.1. Analítica de producto**
  - [ ] Definir eventos clave:
    - Signup, login.
    - Reserva creada/cancelada.
    - Clase completada.
    - Resultado enviado.
    - Pago completado.
    - Uso de funciones IA.
  - [ ] Integrar:
    - Firebase Analytics.
    - Export a BigQuery.

- **9.2. BI para boxes y plataforma**
  - [ ] Construir dashboards:
    - Para tenants: asistencia, ocupación, ingresos, retención.
    - Para plataforma: MRR, churn, crecimiento.

- **9.3. FinOps (costes)**
  - [ ] Estimar coste por tenant:
    - Storage, Firestore, IA, ancho de banda.
  - [ ] Definir alertas:
    - Cuando un tenant supera umbrales de uso (pasar a plan superior).

---

### 10. Marketplace, white-label y extensiones (DESEABLE)

- **10.1. SDK/API pública**
  - [ ] Diseñar endpoints REST/GraphQL:
    - Reservas, clases, resultados, usuarios.
  - [ ] Documentar con OpenAPI/Swagger.

- **10.2. White-label y theming**
  - [ ] Implementar soporte de:
    - Logo, colores, fuentes por tenant.
    - Dominio personalizado (web).

- **10.3. Marketplace**
  - [ ] Definir:
    - Flujos de alta de vendedores (coaches/boxes).
    - Productos (planes, WODs, paquetes).
    - Payouts y comisiones.

---

### 11. Legal, soporte y SLAs

- **11.1. Legal**
  - [ ] Redactar:
    - Términos y condiciones.
    - Política de privacidad.
    - DPA (Data Processing Agreement) para B2B.

- **11.2. Soporte**
  - [ ] Definir:
    - Niveles de soporte por plan (respuesta en X horas).
    - Canales (email, chat, tickets).
  - [ ] Implementar:
    - Módulo de tickets (`support`).
    - Playbooks de resolución.

- **11.3. SLAs**
  - [ ] Establecer:
    - Disponibilidad objetivo (ej. 99.5%).
    - Compromisos de respuesta y resolución.

---

### 12. Prioridades y siguiente paso recomendado

- **Prioridad inmediata**:
  - Cerrar modelo de datos canónico.
  - Cerrar reglas de seguridad y estrategia `tenantId/role`.
  - Implementar `createTenant`, `assignRole`, `createReservation` y Stripe base.
  - Montar estructura Flutter + AuthProvider + GoRouter con guards.
- **Luego**:
  - Núcleo de entrenamiento individual + IA básica.
  - SaaS de agendamiento completo para un box piloto.
  - IA de analítica y reengagement incremental.
