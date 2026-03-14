# Desplegar reglas de Firestore

## Opción A: Con Firebase CLI

### 1. Instalar Firebase CLI (si no lo tienes)

```bash
npm install -g firebase-tools
```

O sin instalar (desde la raíz del proyecto):

```bash
npx firebase-tools deploy --only firestore:rules
```

### 2. Iniciar sesión en Firebase

```bash
firebase login
```

Si ya habías iniciado sesión y da error de credenciales:

```bash
firebase login --reauth
```

Se abrirá el navegador para que inicies sesión con tu cuenta de Google.

### 3. Seleccionar el proyecto (solo la primera vez)

Desde la raíz del proyecto:

```bash
cd /Users/facorrecha/Proyectos/IAEntrenar
firebase use ai-train-7b283
```

(El `projectId` está en tu `firebase.json`.)

## 4. Desplegar solo las reglas de Firestore

Desde la raíz del proyecto (`IAEntrenar`), en la **misma terminal** donde hiciste `login --reauth`:

```bash
cd /Users/facorrecha/Proyectos/IAEntrenar
npx firebase-tools deploy --only firestore:rules
```

O si tienes Firebase CLI instalado globalmente:


```bash
firebase deploy --only firestore:rules
```

Si todo va bien verás algo como:

```
✔  Deploy complete!
Firestore rules: released
```

## 5. Comprobar en la consola

- Entra en [Firebase Console](https://console.firebase.google.com/)
- Proyecto **ai-train-7b283**
- Firestore Database → pestaña **Rules**
- Deberías ver las mismas reglas que en `firestore.rules`

---

---

## Si sigue saliendo `permission-denied` después de desplegar

1. **Comprueba el proyecto**: En Firebase Console, que estés en **ai-train-7b283** y en **Firestore Database → Rules** veas exactamente la regla `allow read, write: if request.auth != null && request.auth.uid == userId` para `users/{userId}`.
2. **Comprueba que el usuario esté autenticado**: El error suele aparecer si la app lee Firestore antes de que Firebase Auth tenga el token (p. ej. al abrir la app). La app ya maneja el error para no cerrarse; si sigue en consola, verifica que el login sea correcto.
3. **Comprueba el documento**: En Firestore → **users** debe existir un documento cuyo ID sea el **UID** del usuario (el mismo que en Authentication → Users). Si el usuario se creó por otro medio y no hay doc en `users/<uid>`, créalo o vuelve a registrar para que `AuthService` lo cree.
4. **Base de datos**: Si usas más de una base de datos (p. ej. otra que no sea `(default)`), las reglas hay que desplegarlas para esa base también.

---

## Opción B: Sin CLI (manual, la más rápida)

1. Abre [Firebase Console](https://console.firebase.google.com/) e inicia sesión.
2. Entra al proyecto **ai-train-7b283**.
3. En el menú izquierdo: **Firestore Database** → pestaña **Rules**.
4. Copia todo el contenido del archivo **`firestore.rules`** de este proyecto (en la raíz).
5. Pega el contenido en el editor de reglas y pulsa **Publicar**.

Con esto las reglas quedan desplegadas sin usar la terminal.

---

## Si al desplegar por CLI sale error 403

Si ves *"Caller does not have required permission to use project"*:

- Tu cuenta de Google debe tener permisos de **Owner** o **Editor** en el proyecto de Firebase, o al menos el rol que permita usar Firestore.
- Un administrador del proyecto puede asignar el rol en: [Google Cloud IAM](https://console.developers.google.com/iam-admin/iam?project=ai-train-7b283).
- Mientras tanto, usa la **Opción B** (manual) con la cuenta que ya tiene acceso al proyecto en la consola de Firebase.
