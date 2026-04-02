# Respuestas — Laboratorio: El Proceso de Compilación en C

**Nombre y Apellido:**
**Legajo:**
**Fecha:**

---

## Instrucciones para completar este archivo

Hay dos tipos de preguntas:

**Preguntas cerradas** — tienen una línea con formato `CLAVE=` que debés completar
con el valor exacto indicado. Esa línea es verificada automáticamente.
Completala **en la misma línea**, sin espacios, sin comillas, respetando
mayúsculas donde se indica. Ejemplo:

```
EJEMPLO_RESPUESTA=SI
```

**Preguntas abiertas** — tienen un bloque `> **R:**` donde escribís con tus palabras.
No se verifican automáticamente; las lee el docente en el Pull Request.

---

## Etapa 1 — Preprocesamiento (`programa.i`)

---

**P1.** Ejecutá `wc -l programa.i` y escribí el número de líneas que obtenés.

<!-- Completá la línea siguiente con el número exacto (solo dígitos, sin espacios): -->
LINEAS_I=

¿Por qué ese número es tan mayor que las ~95 líneas de `programa.c`?

> **R:**

---

**P2.** Ejecutá `grep -n "CUADRADO" programa.i` y copiá la salida completa.

> **R:**

¿El nombre `CUADRADO` aparece tal cual en `programa.i`, o fue reemplazado
por otra cosa? Respondé SI o NO:

<!-- Completá con SI o NO: -->
CUADRADO_EN_I=

---

**P3.** Ejecutá `grep -n '"1\.0"' programa.i` y copiá la línea encontrada.

> **R:**

¿Cuál era el nombre de la macro en `programa.c` que fue reemplazada por `"1.0"`?

<!-- Completá con el nombre exacto de la macro (en mayúsculas, como está en el fuente): -->
NOMBRE_MACRO_VERSION=

---

**P4.** Ejecutá `grep "Archivo fuente principal" programa.i`.
¿El comando encuentra algo o no devuelve nada?

<!-- Completá con SI (si encontró algo) o NO (si no encontró nada): -->
COMENTARIOS_EN_I=

¿Por qué ocurre eso?

> **R:**

---

**P5.** Ejecutá los siguientes dos comandos y copiá la salida de cada uno:
```bash
gcc -E programa.c | grep "Iniciando"
gcc -E -DDEBUG programa.c | grep "Iniciando"
```

> **R:**

¿Agregar `-DDEBUG` hace que aparezca código nuevo en el `.i` que antes no estaba?
Respondé SI o NO:

<!-- Completá con SI o NO: -->
DEBUG_ACTIVA_CODIGO=

---

**P6.** Abrí `programa.i` y buscá las líneas que empiezan con `# ` seguidas de un número
(por ejemplo: `# 1 "<built-in>"`). ¿Qué información comunican esas líneas?
¿De qué archivo proviene el bloque que contiene la declaración de `printf`?

> **R:**

---

## Etapa 2 — Compilación a ensamblador (`programa.s`)

---

**P7.** Ejecutá `grep "area_circulo" programa.s` y copiá la salida.

> **R:**

¿`area_circulo` aparece como una función *definida* en `programa.s`
(con su propio bloque de instrucciones) o solo como una *llamada* (instrucción sin cuerpo)?
Respondé DEFINIDA o LLAMADA:

<!-- Completá con DEFINIDA o LLAMADA: -->
AREA_EN_S=

---

**P8.** Encontrá en `programa.s` la etiqueta `sumar:` o `_sumar:` y copiá
las primeras 4 líneas de instrucciones que le siguen.

> **R:**

Explicá en términos generales qué hacen esas instrucciones
(usá los comentarios del laboratorio como guía):

> **R:**

---

**P9.** Ejecutá `grep "llamadas" programa.s` y copiá la salida.

> **R:**

¿Aparece la variable `llamadas` en el ensamblador?
Respondé SI o NO:

<!-- Completá con SI o NO: -->
LLAMADAS_EN_S=

---

## Etapa 3 — Ensamblado y tabla de símbolos

---

**P10.** Ejecutá `nm programa.o` y copiá la salida completa.

> **R:**

¿Con qué letra aparece `area_circulo` en esa tabla?
Escribí solo la letra (una mayúscula):

<!-- Completá con la letra exacta que muestra nm (U, T, D, etc.): -->
TIPO_AREA_EN_O=

---

**P11.** ¿Por qué `area_circulo` tiene ese tipo en `programa.o`
pero tipo `T` en `matematica.o`?

> **R:**

¿Qué etapa del proceso de compilación resuelve esa diferencia?
Respondé con una palabra: PREPROCESAMIENTO, COMPILACION, ENSAMBLADO o ENLAZADO:

<!-- Completá con una de las cuatro opciones: -->
ETAPA_QUE_RESUELVE=

---

**P12.** Intentá ejecutar `./programa.o` directamente. ¿Qué mensaje aparece?

> **R:**

¿Se puede ejecutar un archivo `.o` directamente?
Respondé SI o NO:

<!-- Completá con SI o NO: -->
EJECUTABLE_O=

---

## Etapa 4 — Enlazado

---

**P13.** Enlazá con `gcc programa.o matematica.o -o programa`.
Ejecutá `nm programa | grep "area_circulo"` y copiá la salida.

> **R:**

¿Con qué letra aparece ahora `area_circulo` en el ejecutable final?
Escribí solo la letra:

<!-- Completá con la letra exacta que muestra nm: -->
TIPO_AREA_ENLAZADO=

---

**P14.** Ejecutá `nm programa | grep "^ *U"` y copiá la salida.

> **R:**

¿Quedan símbolos de tipo `U` en el ejecutable final?
Respondé SI o NO:

<!-- Completá con SI o NO: -->
SIMBOLOS_U_FINAL=

¿Por qué quedan? ¿Quién los resuelve y cuándo?

> **R:**

---

**P15.** Ejecutá `./programa` y copiá la salida completa.

> **R:**

¿Qué valor da `factorial(5)`? Escribí solo el número:

<!-- Completá con el número exacto: -->
FACTORIAL_5=

---

## Conceptos

---

**P16.** Explicá con tus palabras la diferencia entre una **macro función**
como `CUADRADO(x)` y una **función real** como `sumar(a, b)`.
¿En qué etapa "desaparece" cada una? ¿Cuál tiene verificación de tipos?

> **R:**

---

**P17.** ¿Qué diferencia hay entre un símbolo de tipo `T` y uno de tipo `D`
en la salida de `nm`? ¿En qué sección del archivo objeto vive cada uno?

> **R:**

---

**P18.** (Bonus) Ejecutá `otool -L programa` (macOS) o `ldd programa` (Linux)
y copiá la salida.

> **R:**

¿Por qué `libc` no hubo que especificarla explícitamente al enlazar con `gcc`?

> **R:**
