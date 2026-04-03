# Soluciones — Laboratorio: El Proceso de Compilación en C

> **USO EXCLUSIVO DOCENTE** — Esta rama (`docente`) no se distribuye a los estudiantes.

---

## Respuestas cerradas (verificadas por autograding)

| Clave | Respuesta | Puntos |
|---|---|---|
| `LINEAS_I=` | `1802` (macOS) — varía por SO, se acepta 3-4 dígitos | 4 |
| `CUADRADO_EN_I=` | `NO` | 4 |
| `NOMBRE_MACRO_VERSION=` | `VERSION` | 4 |
| `COMENTARIOS_EN_I=` | `NO` | 4 |
| `DEBUG_ACTIVA_CODIGO=` | `SI` | 5 |
| `AREA_EN_S=` | `LLAMADA` | 5 |
| `LLAMADAS_EN_S=` | `SI` | 4 |
| `TIPO_AREA_EN_O=` | `U` | 5 |
| `ETAPA_QUE_RESUELVE=` | `ENLAZADO` | 4 |
| `EJECUTABLE_O=` | `NO` | 4 |
| `TIPO_AREA_ENLAZADO=` | `T` | 4 |
| `SIMBOLOS_U_FINAL=` | `SI` | 5 |
| `FACTORIAL_5=` | `120` | 6 |

**Total respuestas cerradas: 58 pts**

---

## Respuestas abiertas (revisión manual en el PR)

**P1** — ¿Por qué programa.i tiene ~1802 líneas si programa.c tiene 94?
> Porque `#include <stdio.h>` y `#include <stdlib.h>` copian el contenido completo de los headers del sistema en el punto donde están. Esos headers contienen cientos de declaraciones de funciones, typedefs y macros propias de la librería estándar.

---

**P2** — Salida de `grep -n "CUADRADO" programa.i`:
> No debería encontrar nada (o solo si hay menciones en strings). El nombre `CUADRADO` fue reemplazado por su expansión `((5) * (5))` — la macro desaparece.

---

**P3** — Salida de `grep -n '"1\.0"' programa.i` / nombre de la macro:
> La línea encontrada contiene `"1.0"` como string literal. La macro que fue reemplazada se llama `VERSION` (definida como `#define VERSION "1.0"` en el fuente).

---

**P4** — ¿`grep "Archivo fuente principal" programa.i` encuentra algo?
> No encuentra nada. El preprocesador elimina todos los comentarios (`/* */` y `//`) antes de producir el `.i`. Los comentarios no son código C y no se propagan.

---

**P5** — Salida de los dos comandos con/sin `-DDEBUG`:
> Sin `-DDEBUG`: no imprime nada (la macro `LOG` se define vacía).
> Con `-DDEBUG`: imprime algo como `printf("[DEBUG] %s\n", ("Iniciando main"));` porque la compilación condicional activa el bloque `#ifdef DEBUG`.

---

**P6** — ¿Qué son las líneas `# N "archivo"` en programa.i?
> Son marcadores de línea que el preprocesador inserta para registrar el origen de cada bloque. Indican el número de línea y el archivo fuente del que proviene el código siguiente. El compilador los usa para reportar errores con la ubicación correcta en el fuente original.
> La declaración de `printf` proviene de `/usr/include/stdio.h` (o ruta equivalente según el SO).

---

**P7** — `grep "area_circulo" programa.s` / ¿definida o llamada?
> Aparece como instrucción de llamada (ej: `bl _area_circulo` en ARM64 o `call _area_circulo` en x86). No existe etiqueta `_area_circulo:` con su cuerpo → **LLAMADA**.

---

**P8** — Primeras 4 instrucciones de `_sumar:` / qué hacen:
> Típicamente en ARM64:
> ```
> sub  sp, sp, #16    ; reserva espacio en la pila
> str  w0, [sp, #12]  ; guarda parámetro 'a'
> str  w1, [sp, #8]   ; guarda parámetro 'b'
> ldr  w8, [sp, #12]  ; carga 'a' en registro
> ```
> Configuran el stack frame y guardan los parámetros recibidos en registros o posiciones de memoria para poder usarlos en el cuerpo de la función.

---

**P9** — `grep "llamadas" programa.s` / ¿aparece?
> Sí aparece — como referencia a una variable global (`_llamadas`). Las variables globales tienen un símbolo en la tabla y el ensamblador las referencia por nombre → **SI**.

---

**P10** — Salida completa de `nm programa.o` / letra de `area_circulo`:
> `area_circulo` aparece como `U` (Undefined) — está declarada en el header pero su cuerpo está en `matematica.c`, no en `programa.o`.

---

**P11** — ¿Por qué `U` en programa.o pero `T` en matematica.o? / etapa que resuelve:
> Porque `area_circulo` está **definida** (tiene cuerpo) en `matematica.c` → aparece como `T` en `matematica.o`. En `programa.c` solo se **declara** (via el header) y se llama, pero no se define → `U`.
> La etapa que resuelve esa diferencia conectando ambos `.o` es el **ENLAZADO**.

---

**P12** — Mensaje al intentar `./programa.o` / ¿ejecutable?
> Algo como `permission denied` o `cannot execute binary file` o `Exec format error`. Un `.o` no es ejecutable porque tiene símbolos indefinidos y le falta la infraestructura de inicio del proceso (`crt1`). → **NO**.

---

**P13** — Salida de `nm programa | grep area_circulo` / letra:
> Aparece con una dirección concreta y tipo `T`, por ejemplo:
> `00000001000006a0 T _area_circulo`
> El enlazador resolvió la referencia → **T**.

---

**P14** — Salida de `nm programa | grep "^ *U"` / ¿quedan U?
> Quedan símbolos `U` como `_printf`, `_exit`, etc. Son funciones de `libc` dinámica. El enlazador no las copia porque se cargan en tiempo de ejecución; el cargador dinámico (`dyld`/`ld.so`) las resuelve al lanzar el programa → **SI**.

---

**P15** — Salida completa de `./programa` / factorial(5):
```
=== Laboratorio de Compilacion en C (v1.0) ===

sumar(3, 4)       = 7
CUADRADO(5)      = 25
MAX(7, 12)        = 12
----------------------------------------
area_circulo(5.0) = 78.5398
Factoriales:
  0! = 1
  1! = 1
  2! = 2
  3! = 6
  4! = 24
  5! = 120
----------------------------------------
Llamadas a sumar(): 1
```
`factorial(5) = 120`

---

**P16** — Diferencia macro función vs función real:
> La macro se expande en **preprocesamiento** (el compilador nunca la ve), no tiene verificación de tipos, no genera overhead de llamada pero puede producir efectos secundarios si el argumento se evalúa más de una vez. La función real se compila en la etapa de **compilación**, tiene verificación de tipos, firma definida, y el compilador puede optimizarla (inlining). La macro "desaparece" en preprocesamiento; la función real persiste hasta el enlazado.

---

**P17** — Diferencia entre símbolo `T` y `D`:
> `T` (Text): definido en la sección de código ejecutable (`.text`). Son funciones — instrucciones de máquina.
> `D` (Data): definido en la sección de datos inicializados (`.data`). Son variables globales que tienen un valor inicial explícito en el código fuente.

---

**P18** — Bonus `otool -L` / ¿por qué no hace falta especificar libc?
> `libc` (o `libSystem` en macOS) la incluye `gcc` automáticamente como parte de su configuración por defecto. El driver de `gcc` agrega `-lc` al invocar al enlazador real sin que el programador lo pida. Es la biblioteca más básica de C y sería un error de usabilidad tener que especificarla siempre.

---

## Archivos intermedios en esta rama

| Archivo | Generado con |
|---|---|
| `programa.i` | `gcc -E programa.c -o programa.i` |
| `programa.s` | `gcc -S programa.c -o programa.s` |
| `salidas/nm_programa_o.txt` | `nm programa.o > salidas/nm_programa_o.txt` |
| `salidas/nm_ejecutable.txt` | `nm programa > salidas/nm_ejecutable.txt` |
| `salidas/salida_debug.txt` | `gcc -DDEBUG ... && ./programa_debug > salidas/salida_debug.txt` |

Generados en macOS (Apple Silicon / ARM64). En Linux o Windows los archivos `.s` y la salida de `nm` tendrán diferencias de sintaxis pero los conceptos son los mismos.
