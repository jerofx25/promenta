# Fase 1 — Análisis y diseño: Métricas de capacidades y RM

Documento de diseño para la funcionalidad de registro de RM y métricas de capacidades físicas (strength, endurance, speed, mobility, cardio), persistencia en Firestore e integración con FitnessTrackerScreen.

---

## 1. Explicación de la funcionalidad

### Qué vamos a construir

Un **sistema de métricas físicas** que permita:

1. **Registrar métricas de fuerza (RM)**  
   Ejercicio + valor + unidad (kg/lb), con cálculo de porcentajes 10–100% y persistencia en Firestore.

2. **Registrar métricas de otras capacidades**  
   No solo peso: repeticiones (push-ups), tiempos (sprint 100 m, 2k row, 5k run), scores (movilidad), etc., siempre con unidad y tipo de capacidad.

3. **Histórico por usuario, ejercicio y capacidad**  
   Consultar evolución en el tiempo para gráficas y comparativas.

4. **Alimentar el radar chart y gráficas**  
   FitnessTrackerScreen consumirá estos datos: normalización a escala 0–10 (o configurable) para el radar y datasets para gráficas históricas.

Todo debe estar **asociado al usuario autenticado** (Firebase Auth), ser **multi-tenant** (cada usuario solo ve y escribe sus datos) y **escalable** (más tipos de capacidad o unidades en el futuro sin reescribir el modelo).

### Flujo de datos resumido

```
UI (RM Calculator / formularios)
    → Presentation (Cubit/Bloc): validación, estado
    → Domain: use cases (guardar, listar, histórico, calcular %, normalizar)
    → Data: repositorio → Firestore (colección user_metrics)
FitnessTrackerScreen
    → Use case “obtener métricas para radar”
    → Repositorio → Firestore
    → Normalización a Map<String, double>
    → Radar chart + gráficas históricas
```

---

## 2. Riesgos y decisiones importantes

### Riesgos

| Riesgo | Mitigación |
|--------|------------|
| Mezclar “ejercicio de fuerza” con “capacidad” y no poder extender | Modelo unificado: **una métrica** = usuario + tipo de capacidad + ejercicio (o “nombre”) + valor + unidad + fechas. El “tipo” distingue fuerza, resistencia, velocidad, etc. |
| Unidades heterogéneas (kg, lb, rep, s, min) en un solo campo | Campo `value` numérico + `unit` string normalizado. Conversión kg/lb en dominio; para radar se normaliza por tipo/capacidad. |
| Queries Firestore costosas o sin índices | Índices compuestos `userId` + `capacityType` + `recordedAt` (desc). Subcolecciones por usuario si crece mucho. |
| Radar con escalas distintas (kg vs rep vs segundos) | Capa de **normalización** en dominio: por capacidad/ejercicio se define un “mejor valor” y se mapea a 0–maxValue (ej. 10). |
| Duplicar lógica de negocio en UI | Cálculo de % RM y conversión de unidades en **casos de uso** o servicios de dominio; la UI solo muestra. |

### Decisiones clave

1. **Una sola colección de “registros de métrica”**  
   No una colección por tipo (RM vs resistencia vs cardio). Cada documento = un registro (una fecha, un valor, un ejercicio, un tipo de capacidad). Facilita histórico, queries por usuario y por tipo, y evolución (nuevos tipos = nuevo enum, no nueva colección).

2. **userId en documento como string**  
   Ver sección Firestore más abajo: usamos `userId` (string) para filtros y seguridad; `user_ref` (DocumentReference) opcional para referencias explícitas si en el futuro se necesitan joins o reglas más complejas. Para tu caso, **solo `userId` es suficiente** y evita acoplamiento a la ruta de `users`.

3. **Cubit para la pantalla de métricas**  
   La pantalla tiene formularios, validación, loading/success/error y listados. Cubit encaja bien: menos boilerplate que Bloc, suficiente para un flujo por pantalla. Si más adelante necesitas eventos explícitos (p. ej. “MétricaGuardada” para analytics), se puede migrar a Bloc.

4. **Dominio en feature `workout` o nuevo feature `metrics`**  
   Recomendación: **nuevo feature `metrics`** (o `fitness_metrics`). La calculadora RM actual vive en `workout` y puede **consumir** el dominio de métricas, pero las entidades, repositorio y casos de uso de “métrica de capacidad” pertenecen a un módulo que también alimenta **progress** (FitnessTrackerScreen). Así evitas que `workout` dependa de `progress` y mantienes responsabilidades claras: `workout` = sesiones/entrenos; `metrics` = capacidades y RM como datos reutilizables.

---

## 3. Diseño de Firestore

### Colección: `user_metrics`

Cada documento representa **un registro puntual** de una métrica (un valor en una fecha).

| Campo | Tipo | Obligatorio | Descripción |
|-------|------|-------------|-------------|
| `userId` | string | Sí | UID de Firebase Auth. Permite reglas de seguridad y queries por usuario. |
| `capacityType` | string | Sí | Enum: `strength` \| `endurance` \| `speed` \| `mobility` \| `cardio`. |
| `exerciseKey` | string | Sí | Identificador estable del ejercicio/capacidad. Ej: `back_squat`, `push_ups`, `run_5k`, `shoulder_mobility_test`. |
| `exerciseDisplayName` | string | Sí | Nombre para mostrar: "Back Squat", "50 push-ups", "5K run". |
| `value` | number | Sí | Valor numérico (peso en kg/lb, repeticiones, segundos, etc.). Siempre en **unidad canónica** (ver abajo). |
| `unit` | string | Sí | Unidad canónica: `kg`, `lb`, `reps`, `seconds`, `minutes`, `score`. |
| `sourceUnit` | string? | No | Unidad en la que el usuario introdujo el valor, si difiere de la canónica (ej. usuario en lb, guardamos kg). |
| `recordedAt` | timestamp | Sí | Fecha/hora del registro (permite histórico y ordenación). |
| `createdAt` | timestamp | Sí | Creación del documento. |
| `updatedAt` | timestamp | Sí | Última actualización. |
| `metadata` | map | No | Reservado (ej. notas, RPE, sesión asociada). |

**Unidad canónica:**  
- Fuerza: guardar siempre en **kg** internamente; si el usuario elige lb, convertir y guardar `value` en kg y `sourceUnit: 'lb'`.  
- Tiempos: **seconds** (número; 8:12 = 492 s).  
- Repeticiones: **reps**.  
- Tests con puntuación: **score**.

**Por qué `userId` (string) y no solo `user_ref`:**  
- Las reglas de seguridad de Firestore suelen usar `request.auth.uid` (string). Con `userId` el filtro `resource.data.userId == request.auth.uid` es directo.  
- Las queries son más simples: `where('userId', isEqualTo: uid)`.  
- DocumentReference obliga a que la ruta `users/{uid}` exista y acopla la estructura; para métricas no es necesario.  
- Si más adelante quieres “perfil público” o joins, puedes añadir `userRef` sin romper lo existente.

**ID del documento:**  
- Opción A: **Auto-ID** de Firestore. Ventaja: simple, evita colisiones. Desventaja: no puedes “actualizar el registro de hoy” por ID sin una query.  
- Opción B: **ID compuesto** tipo `{userId}_{capacityType}_{exerciseKey}_{date}` (fecha al día). Ventaja: idempotencia “un registro por ejercicio por día” si quieres “actualizar hoy”.  
- **Recomendación:** Auto-ID + **query por userId + capacityType + exerciseKey + recordedAt** para “último valor” o “histórico”. Si en producto quieres “solo un registro por ejercicio por día”, el caso de uso puede hacer “upsert” buscando por userId, exerciseKey y fecha a nivel de día y luego actualizar o crear. No hace falta comprimirlo en el ID.

### Índices compuestos recomendados

1. **Listar métricas del usuario (y filtrar por tipo)**  
   - Colección: `user_metrics`  
   - Campos: `userId` (Asc), `recordedAt` (Desc)  
   - Uso: pantalla de listado / histórico.

2. **Por usuario y tipo de capacidad**  
   - Campos: `userId` (Asc), `capacityType` (Asc), `recordedAt` (Desc)  
   - Uso: “dame todas las de fuerza” o “todas las de cardio” para radar y gráficas.

3. **Por usuario y ejercicio**  
   - Campos: `userId` (Asc), `exerciseKey` (Asc), `recordedAt` (Desc)  
   - Uso: histórico por ejercicio (gráfica de evolución de Back Squat).

### Reglas de seguridad (resumen)

- `read`, `write`: solo si `resource.data.userId == request.auth.uid` (en create, validar que `request.resource.data.userId == request.auth.uid`).
- Validar en creación que los campos obligatorios existan y `userId` no se pueda sobrescribir.

### Coste y rendimiento

- Evitar leer toda la colección: siempre filtrar por `userId`.  
- Para el radar solo necesitas el **valor más reciente por (userId, capacityType)** o por (userId, exerciseKey) según cómo definas “valor actual” (p. ej. último registro por capacidad). Una query por usuario + ordenación por `recordedAt` desc con límite por tipo o un solo snapshot con múltiples queries en paralelo (una por capacityType) mantiene lecturas acotadas.  
- Histórico: paginar con `startAfterDocument` / `limit` para no cargar miles de documentos.

---

## 4. Diseño de entidades y modelos

### 4.1. Entidad de dominio: `FitnessMetricRecord`

Vive en **domain/entities** (feature `metrics` o `fitness_metrics`). Representa un registro de métrica tal como lo usa el dominio (sin detalles de Firestore).

```dart
// Propuesta de campos (implementación en Fase 2)
class FitnessMetricRecord {
  final String id;                    // Firestore document id
  final String userId;
  final CapacityType capacityType;    // enum
  final String exerciseKey;
  final String exerciseDisplayName;
  final double value;
  final MetricUnit unit;
  final String? sourceUnit;
  final DateTime recordedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;
}
```

**CapacityType (enum):**  
`strength`, `endurance`, `speed`, `mobility`, `cardio`.

**MetricUnit (enum):**  
`kg`, `lb`, `reps`, `seconds`, `minutes`, `score`.  
(O bien string en dominio y validación en use case; enum da más tipo fuerte.)

### 4.2. Modelo de datos (Data layer)

El **modelo de datos** (ej. `FitnessMetricRecordModel`) en la capa data puede extender o contener la entidad y añadir:

- `fromFirestore(Map<String, dynamic> data, String id)`
- `toFirestore()` → Map para `set`/`update`

Así el dominio no conoce Firestore ni nombres de campos; el mapeo es responsabilidad de la capa data.

### 4.3. Valor actual por capacidad (para radar)

Para el radar no hace falta una entidad nueva; es una **proyección** de los registros:

- Por cada `CapacityType` (o por cada “eje” del radar, si quieres mapear fuerza → “Back Squat” u otro representante), se obtiene el **último registro** (ordenando por `recordedAt` desc).
- Esos valores (en unidades distintas) se pasan por un **servicio de normalización** que devuelve `Map<String, double>` (nombre de capacidad → valor 0–maxValue). La entidad sigue siendo `FitnessMetricRecord`; la normalización es un caso de uso o servicio de dominio que consume listas de `FitnessMetricRecord`.

---

## 5. Diseño de casos de uso

Todos en la capa **domain** del feature de métricas, invocados desde presentation (Cubit) o desde progress (FitnessTracker).

| Caso de uso | Entrada | Salida | Responsabilidad |
|-------------|--------|--------|------------------|
| **SaveMetric** | FitnessMetricRecord (o DTO con datos del formulario) | void / id del doc | Convierte unidades si hace falta, valida, delega al repo. |
| **GetUserMetrics** | userId, opcional capacityType, opcional limit | List\<FitnessMetricRecord> | Listado para listas e histórico. |
| **GetHistoryByExercise** | userId, exerciseKey | List\<FitnessMetricRecord> | Histórico ordenado por fecha para gráfica por ejercicio. |
| **GetLatestMetricsForRadar** | userId, lista de capacityTypes (o ejes deseados) | List\<FitnessMetricRecord> (uno por tipo/capacidad) o ya Map | Obtener “último valor” por capacidad. |
| **NormalizeForRadar** | List\<FitnessMetricRecord> (o Map capacityType → value), config escalas | Map\<String, double> | Convertir valores a escala 0–maxValue para el radar. |
| **CalculateRmPercentages** | value (kg), step (ej. 5) | List\<{percent, weight}> | Cálculo puro 10%–100% RM. |
| **ConvertWeightUnit** | value, fromUnit, toUnit | double | kg ↔ lb. |
| **UpdateMetric** | id, campos a actualizar | void | Actualizar documento existente. |
| **DeleteMetric** | id | void | Eliminar registro (si aplica en producto). |

**Dónde va la lógica:**  
- **SaveMetric:** validación (valor > 0, unidades coherentes con capacityType); conversión lb→kg si aplica; llamada a repository.  
- **NormalizeForRadar:** reglas por capacidad (ej. fuerza: 0–200 kg → 0–10; resistencia: 0–100 reps → 0–10; tiempo: invertir o scale para que “mejor” = mayor). Esto puede ser un servicio/helper en domain o en un use case dedicado que devuelva ya el `Map<String, double>` que espera el radar.

---

## 6. Integración con FitnessTrackerScreen

### 6.1. Consumir métricas

- **Responsable:** Feature **progress** (o la pantalla FitnessTrackerScreen).  
- **Dependencia:** El feature progress debe poder **obtener** métricas; no debe depender del feature workout en detalle de implementación.  
- **Opciones:**  
  - Inyectar un **GetLatestMetricsForRadar** (y opcionalmente **NormalizeForRadar**) en el Cubit/Bloc de progress, que a su vez use el **MetricsRepository** (interface en domain, implementación en data con Firestore).  
  - O un **MetricsSummaryRepository** que exponga “métricas listas para radar” (dominio de progress); bajo el capó llama al repositorio de métricas y normaliza.  
- Recomendación: **Use case en feature metrics** que devuelva `Map<String, double>` listo para radar (GetNormalizedRadarData). Progress solo llama a ese use case y pinta el radar; así la normalización y el origen de datos viven en metrics.

### 6.2. Transformar para el radar

- Entrada: lista de `FitnessMetricRecord` (último por capacidad) o ya un mapa capacityType → value.  
- **Normalización:** Por cada capacidad, aplicar escala configurable (ej. min, max, invertir si “menor es mejor”). Salida: mismo `Map<String, double>` que hoy usa `FitnessRadarChart` (ej. `{'Fuerza': 7.2, 'Resistencia': 6.0, ...}`).  
- Orden de ejes: fijo en código o config (ej. lista ordenada de capacidades) para que el radar no cambie de orden entre sesiones.

### 6.3. Datasets para gráficas históricas

- Por **ejercicio** (ej. Back Squat): **GetHistoryByExercise(userId, 'back_squat')** → lista ordenada por `recordedAt`.  
- Eje X: fecha; eje Y: valor (en unidad original o normalizada). Si hay varias unidades en el tiempo, decidir si se muestran en unidad canónica (kg) o se permite ver en lb en UI.  
- Por **capacidad** (ej. “Fuerza”): agregar últimos N registros de cualquier ejercicio de tipo strength (o el “representante” que elijas para ese eje del radar). Depende de si en producto quieres “una curva por capacidad” o “una curva por ejercicio”.

### 6.4. Valor “actual” más relevante por capacidad

- **Definición:** Para cada `CapacityType`, el valor actual es el registro con `recordedAt` más reciente que corresponda a ese tipo (y opcionalmente a un `exerciseKey` representativo, ej. “back_squat” para fuerza).  
- Implementación: query `userId` + `capacityType`, orden `recordedAt` desc, limit 1; o por cada tipo una query en paralelo. Si defines “un ejercicio por capacidad” (ej. strength = back_squat), entonces **GetHistoryByExercise** para ese ejercicio da la serie y el primer elemento es el “actual”.

### 6.5. Múltiples registros por capacidad y ejercicio

- **Por ejercicio:** Varios registros con el mismo `exerciseKey` = histórico (gráfica de evolución).  
- **Por capacidad:** Varios ejercicios con el mismo `capacityType` (ej. back_squat, deadlift para fuerza). Para el radar hace falta una **estrategia de agregación**: p. ej. usar un solo “ejercicio representante” por capacidad, o promediar/promediar ponderado los valores normalizados de todos los ejercicios de esa capacidad. La opción más simple y predecible: **un ejercicio representante por capacidad** (configurable o por defecto), y el “valor actual” de esa capacidad = último registro de ese ejercicio.

---

## 7. Resumen de acuerdos para Fase 2

- **Colección:** `user_metrics`; documentos con userId, capacityType, exerciseKey, exerciseDisplayName, value, unit, recordedAt, createdAt, updatedAt.  
- **Entidad:** `FitnessMetricRecord` con enums CapacityType y MetricUnit.  
- **Casos de uso:** SaveMetric, GetUserMetrics, GetHistoryByExercise, GetLatestMetricsForRadar / GetNormalizedRadarData, CalculateRmPercentages, ConvertWeightUnit, UpdateMetric, DeleteMetric.  
- **Normalización:** Servicio/use case que transforma registros a `Map<String, double>` para el radar con escalas por capacidad.  
- **Integración FitnessTracker:** Obtener datos vía use case de métricas; radar y gráficas históricas consumen esos datos; “valor actual” = último registro por capacidad (o por ejercicio representante).  
- **State management pantalla métricas:** Cubit con estados loading/success/error y formulario validado.  
- **Feature nuevo:** `metrics` (o `fitness_metrics`) con data/domain/presentation; `workout` (RM calculator) y `progress` (FitnessTracker) consumen dominio de metrics.

Con esto la Fase 1 queda cerrada para pasar a la **Fase 2 — Implementación técnica** cuando lo indiques.

---

## Fase 2 — Implementación técnica (resumen)

### Archivos creados

| Capa | Ruta |
|------|------|
| Domain | `lib/features/metrics/domain/entities/capacity_type.dart` |
| Domain | `lib/features/metrics/domain/entities/metric_unit.dart` |
| Domain | `lib/features/metrics/domain/entities/fitness_metric_record.dart` |
| Domain | `lib/features/metrics/domain/repositories/metrics_repository.dart` |
| Domain | `lib/features/metrics/domain/usecases/save_metric.dart` |
| Domain | `lib/features/metrics/domain/usecases/convert_weight_unit.dart` |
| Domain | `lib/features/metrics/domain/usecases/calculate_rm_percentages.dart` |
| Domain | `lib/features/metrics/domain/usecases/get_user_metrics.dart` |
| Domain | `lib/features/metrics/domain/usecases/get_history_by_exercise.dart` |
| Domain | `lib/features/metrics/domain/usecases/get_normalized_radar_data.dart` |
| Domain | `lib/features/metrics/domain/usecases/update_metric.dart` |
| Domain | `lib/features/metrics/domain/usecases/delete_metric.dart` |
| Data | `lib/features/metrics/data/models/fitness_metric_record_model.dart` |
| Data | `lib/features/metrics/data/datasources/firestore_metrics_datasource.dart` |
| Data | `lib/features/metrics/data/repositories/firestore_metrics_repository.dart` |
| Application | `lib/features/metrics/application/metrics_state.dart` |
| Application | `lib/features/metrics/application/metrics_cubit.dart` |

### Archivos editados

- `lib/main.dart` — Provider de `MetricsRepository`, BlocProvider de `MetricsCubit`.
- `lib/features/workout/presentation/screens/rm_calculator_screen.dart` — Import de metrics; al añadir/actualizar ejercicio se llama `MetricsCubit.saveMetric` (sincronización a Firestore).
- `lib/features/progress/presentation/screens/fitness_tracker_screen.dart` — Carga de datos del radar vía `MetricsCubit.loadRadarData`; el radar usa `state.radarData` o datos de ejemplo si no hay métricas.
- `firestore.indexes.json` — Índices compuestos para `user_metrics` (userId + recordedAt; userId + capacityType + recordedAt; userId + exerciseKey + recordedAt).
- `firestore.rules` — Reglas de lectura/escritura para `user_metrics` por `userId == request.auth.uid`.

### Despliegue

1. **Índices:** `firebase firestore:indexes` o desplegar `firestore.indexes.json` desde Firebase Console.
2. **Reglas:** `firebase deploy --only firestore:rules`.
