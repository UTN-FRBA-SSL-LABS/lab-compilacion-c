# Laboratorio: El Proceso de Compilación en C

**Materia:** Sintaxis y Semántica de los Lenguajes
**Tema:** Proceso de compilación — de código fuente a ejecutable

---

## Requisitos previos — Instalación de herramientas

Para realizar este laboratorio se necesitan dos herramientas: **GCC** (compilador de C) y **Clang** (compilador alternativo que usaremos para inspeccionar fases internas). Seguir las instrucciones según el sistema operativo.

### Windows

**Paso 1 — Instalar GCC mediante MSYS2**

MSYS2 es un entorno que provee GCC y herramientas Unix en Windows.

1. Descargar el instalador desde: `https://www.msys2.org`
2. Ejecutar el instalador y seguir los pasos (dejar la ruta por defecto `C:\msys64`).
3. Al finalizar, abrir la terminal **MSYS2 UCRT64** (buscarla en el menú Inicio).
4. En esa terminal, ejecutar:

```bash
pacman -Syu
pacman -S mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-clang
```

5. Agregar al PATH de Windows la carpeta `C:\msys64\ucrt64\bin` (Panel de control → Variables de entorno → Path → Nuevo).
6. Abrir una nueva terminal (CMD o PowerShell) y verificar:

```powershell
gcc --version
clang --version
```

**Alternativa: instalar solo Clang con winget** (si GCC ya está instalado por otro medio):

```powershell
winget install LLVM.LLVM
```

---

### macOS

Tanto GCC como Clang se instalan juntos con las **Xcode Command Line Tools**. En una terminal:

```bash
xcode-select --install
```

Aparece un cuadro de diálogo; aceptar la instalación. Cuando termine, verificar:

```bash
gcc --version
clang --version
```

> En macOS, el comando `gcc` en realidad invoca Clang internamente (Apple reemplazó GCC por Clang). Para este laboratorio no hay diferencia práctica: todos los comandos funcionan igual.

---

### Linux (Ubuntu / Debian y derivados)

```bash
sudo apt update
sudo apt install gcc clang
```

Verificar:

```bash
gcc --version
clang --version
```

### Linux (Fedora / RHEL / Rocky)

```bash
sudo dnf install gcc clang
```

---

### Verificación final (todos los sistemas)

Ejecutar estos tres comandos. Si todos muestran un número de versión, el entorno está listo:

```bash
gcc --version
clang --version
nm --version        # en macOS puede decir "Apple LLVM" — está bien
```

---

## Introducción

Cuando escribimos un programa en C y lo "compilamos", en realidad ocurren **cuatro etapas distintas y separadas**. Cada una toma como entrada el resultado de la anterior y produce una representación diferente del programa:

```
programa.c
    │
    ▼ [1] PREPROCESAMIENTO      gcc -E
programa.i  (código C expandido)
    │
    ▼ [2] COMPILACIÓN           gcc -S
programa.s  (código ensamblador)
    │
    ▼ [3] ENSAMBLADO            gcc -c
programa.o  (código objeto binario)
    │
    ▼ [4] ENLAZADO              gcc (ld)
programa    (ejecutable final)
```

Este laboratorio recorre cada etapa de forma práctica usando los archivos fuente provistos.

---

## Conceptos previos

Antes de empezar es importante tener claros tres conceptos que aparecen a lo largo del laboratorio.

### ¿Qué es una directiva?

Una **directiva** es una instrucción dirigida al **preprocesador**, no al compilador. Se reconocen porque comienzan con `#`. No son código C: son órdenes de procesamiento de texto que se ejecutan **antes** de que el compilador vea el código.

```c
#include <stdio.h>      // directiva: "incluir este archivo aquí"
#define PI 3.14159      // directiva: "reemplazar PI por 3.14159 en todo el texto"
#ifdef DEBUG            // directiva: "incluir este bloque sólo si DEBUG está definido"
```

Las directivas no generan código de máquina; desaparecen antes de la compilación.

### ¿Qué es una macro?

Una **macro** es un nombre definido con `#define` que el preprocesador reemplaza textualmente en el código fuente. Hay dos tipos:

- **Macro de objeto** (constante simbólica): reemplaza un nombre por un valor.
  ```c
  #define PI    3.14159     // PI se reemplaza por 3.14159
  #define LIMITE 5          // LIMITE se reemplaza por 5
  ```

- **Macro función**: reemplaza un nombre seguido de argumentos por una expresión.
  ```c
  #define CUADRADO(x)  ((x) * (x))   // CUADRADO(3) → ((3) * (3))
  #define MAX(a, b)    ((a) > (b) ? (a) : (b))
  ```

La diferencia fundamental con una función real es que **la macro se expande en tiempo de preprocesamiento**: el compilador nunca la ve; sólo ve el código ya expandido. Esto tiene ventajas (sin overhead de llamada a función) y riesgos (sin verificación de tipos).

### ¿Qué es una llamada a función externa?

Una **llamada a función externa** ocurre cuando el código de un archivo `.c` llama a una función que **no está definida en ese mismo archivo**. Por ejemplo, en `programa.c`:

```c
area_circulo(radio);   // definida en matematica.c → externa
printf("...");         // definida en libc          → externa
```

Durante la compilación, el compilador sólo necesita saber la **declaración** (firma) de esas funciones —qué parámetros reciben y qué devuelven— para verificar que se las llama correctamente. La **definición** real (el cuerpo de la función) se buscará más tarde, en la etapa de enlazado.

---

## Archivos del laboratorio

| Archivo | Rol |
|---|---|
| `programa.c` | Archivo fuente principal. Contiene `main()`, usa macros, directivas y llama a funciones externas. |
| `matematica.h` | Encabezado con macros (`PI`, `CUADRADO`, `MAX`) y prototipos de funciones. |
| `matematica.c` | Implementación de `area_circulo()` y `factorial()`. Es una **unidad de traducción independiente**. |

> **Unidad de traducción:** cada archivo `.c` (con sus headers incluidos) que el compilador procesa de forma independiente. El enlazador luego las une.

---

## Etapa 1 — Preprocesamiento

### Concepto teórico

El **preprocesador** es un paso anterior a la compilación propiamente dicha. No entiende C: trabaja puramente como un procesador de texto que sigue directivas que comienzan con `#`.

Sus tareas son:

| Directiva | Tarea |
|---|---|
| `#include <archivo>` | Copia el contenido del archivo en ese punto |
| `#include "archivo"` | Igual, pero busca primero en el directorio local |
| `#define NOMBRE valor` | Define una macro: toda ocurrencia de `NOMBRE` se reemplaza por `valor` |
| `#define MACRO(x) expr` | Define una macro función: se expande con sustitución de parámetros |
| `#ifdef / #ifndef / #endif` | Inclusión condicional de bloques de código |
| Comentarios `/* */` y `//` | Se **eliminan** completamente |

El resultado es un archivo `.i` con código C "puro": sin directivas, sin comentarios, con todas las macros ya expandidas.

### Práctica

Ejecutar sólo el preprocesador sobre `programa.c`:

```bash
gcc -E programa.c -o programa.i
```

Abrir el archivo generado y observar:

```bash
# Ver cuántas líneas tiene (eran ~70 en el fuente original)
wc -l programa.i
```

Resultado esperado: **~1802 líneas**. ¿Por qué tantas? Porque `#include <stdio.h>` y `#include <stdlib.h>` copiaron cientos de declaraciones del sistema.

#### Herramienta: `grep`

`grep` (Global Regular Expression Print) busca líneas que coincidan con un patrón dentro de uno o varios archivos. Su forma básica es:

```bash
grep "patrón" archivo
```

Si no encuentra nada, no imprime nada. Si el patrón no existe en el archivo, el comando termina en silencio. Se usará a lo largo del laboratorio para verificar qué contiene (o no contiene) cada producto intermedio.

Algunas opciones útiles:
- `-n` muestra el número de línea de cada coincidencia
- `-c` cuenta cuántas líneas coinciden (sin mostrarlas)
- `\|` en el patrón significa "o" (busca una cosa o la otra)

#### Observación 1 — Los comentarios desaparecen

El encabezado de `programa.c` tenía este comentario de bloque:
```c
/*
 * programa.c  —  Archivo fuente principal
 * ...
 */
```
En `programa.i` no existe ningún rastro de él. Buscar para confirmar:
```bash
grep "Archivo fuente principal" programa.i   # no debe encontrar nada
```

#### Observación 2 — Las macros se expanden

En el fuente original:
```c
printf("=== Laboratorio de Compilacion en C (v%s) ===\n\n", VERSION);
printf("CUADRADO(%d)      = %d\n", LIMITE, CUADRADO(LIMITE));
```

En `programa.i` esas líneas quedaron como:
```c
printf("=== Laboratorio de Compilacion en C (v%s) ===\n\n", "1.0");
printf("CUADRADO(%d)      = %d\n", 5, ((5) * (5)));
```

Buscar en el archivo para verificarlo:
```bash
grep -n "1.0\|CUADRADO" programa.i
```

Nótese que `CUADRADO(5)` se expande a `((5) * (5))` — con los paréntesis extra que evitan errores de precedencia de operadores. Si la macro fuera `#define CUADRADO(x) x * x` (sin paréntesis), entonces `CUADRADO(1+2)` daría `1+2 * 1+2 = 5` en lugar de `9`.

#### Observación 3 — Compilación condicional

`programa.c` tiene este bloque:
```c
#ifdef DEBUG
    #define LOG(msg)  printf("[DEBUG] %s\n", (msg))
#else
    #define LOG(msg)  /* vacío */
#endif
```

Sin la bandera `-DDEBUG`, la macro `LOG` se define como vacía, así que la línea `LOG("Iniciando main")` desaparece del código:

```bash
# Sin DEBUG: LOG no genera código
gcc -E programa.c | grep "Iniciando"   # no encuentra nada

# Con DEBUG: LOG se expande a printf
gcc -E -DDEBUG programa.c | grep "Iniciando"
# Resultado: printf("[DEBUG] %s\n", ("Iniciando main"));
```

> **Conclusión:** la compilación condicional permite incluir o excluir código en tiempo de preprocesamiento, **antes** de que el compilador analice el código.

---

## Etapa 2 — Compilación (Análisis + Generación de código)

### Concepto teórico

Esta etapa es la que suele llamarse "compilación" en sentido estricto. Toma el código C preprocesado y lo traduce a **lenguaje ensamblador**. Internamente se divide en fases:

```
Código C preprocesado
        │
        ▼
   ┌─────────────────┐
   │ Análisis Léxico │  Identifica tokens: palabras clave, identificadores,
   │  (Scanner)      │  literales, operadores, delimitadores.
   └────────┬────────┘
            │ flujo de tokens
            ▼
   ┌──────────────────┐
   │ Análisis         │  Verifica que los tokens forman estructuras
   │ Sintáctico       │  gramaticalmente correctas (construye el AST:
   │  (Parser)        │  Árbol de Sintaxis Abstracta).
   └────────┬─────────┘
            │ AST
            ▼
   ┌──────────────────┐
   │ Análisis         │  Verifica tipos, declaraciones previas,
   │ Semántico        │  compatibilidad de operaciones.
   └────────┬─────────┘
            │ AST anotado
            ▼
   ┌──────────────────┐
   │ Generación de    │  Produce código en lenguaje ensamblador
   │ Código           │  (dependiente de la arquitectura del procesador).
   └──────────────────┘
```

### Las fases internas del compilador

El diagrama resume cuatro fases. Acá se explica qué hace concretamente cada una.

#### Análisis léxico (scanner)

El código fuente preprocesado es, a los ojos del compilador, una secuencia de caracteres sin estructura. La primera tarea es dividir esa cadena de caracteres en **tokens**: las unidades atómicas con significado del lenguaje.

Un **token** tiene dos atributos: su **clase** (qué tipo de cosa es) y su **lexema** (el texto exacto en el fuente). Las clases de tokens en C son:

| Clase | Ejemplos |
|---|---|
| Palabra clave (keyword) | `int`, `return`, `if`, `while`, `void` |
| Identificador | `sumar`, `resultado`, `llamadas`, `main` |
| Literal numérico | `3`, `4`, `5.0`, `3.14` |
| Literal de cadena | `"Laboratorio"`, `"%d\n"` |
| Operador | `+`, `++`, `=`, `>`, `*` |
| Delimitador / puntuador | `(`, `)`, `{`, `}`, `;`, `,` |

El analizador léxico **no sabe nada de gramática**: no distingue si un `(` abre la firma de una función o la condición de un `if`. Sólo reconoce patrones usando expresiones regulares (o autómatas finitos equivalentes). Su salida es un flujo lineal de tokens que pasa a la siguiente fase.

Un error léxico ocurre cuando el scanner encuentra una secuencia de caracteres que no forma ningún token válido del lenguaje (por ejemplo, un carácter `@` suelto en C, o una cadena sin cerrar).

#### Análisis sintáctico (parser)

El parser toma el flujo de tokens y verifica que su **orden y estructura** respetan la gramática del lenguaje. El resultado es el **AST** (ver más abajo). Si los tokens están en un orden gramaticalmente inválido (falta un `;`, un `{` sin cerrar, etc.), se produce un error sintáctico.

#### Análisis semántico

Con el árbol construido, el análisis semántico verifica el **significado** de las construcciones: que los tipos sean compatibles en una asignación, que una función se llame con la cantidad correcta de argumentos, que una variable esté declarada antes de usarse. Es la fase que detecta errores que son gramaticalmente correctos pero sin sentido, como sumar un entero y una cadena de texto.

#### ¿Qué es el AST?

El **AST** (Abstract Syntax Tree, Árbol de Sintaxis Abstracta) es la estructura de datos central del compilador: una representación jerárquica en forma de árbol del programa. Cada nodo del árbol representa una construcción del lenguaje.

Se llama "abstracto" porque **omite detalles sintácticos superfluos** que no aportan significado: los paréntesis de agrupación, los puntos y coma, las llaves. Lo que importa es la estructura lógica, no los tokens exactos que la delimitaron.

Por ejemplo, el código fuente:
```c
int sumar(int a, int b) {
    llamadas++;
    return a + b;
}
```
produce un árbol como éste:
```
FunctionDecl  "sumar"  tipo: int(int, int)
├── ParmVarDecl  "a"  tipo: int
├── ParmVarDecl  "b"  tipo: int
└── CompoundStmt  (el cuerpo {})
    ├── UnaryOperator  "++"  (postfijo)
    │   └── DeclRefExpr  "llamadas"
    └── ReturnStmt
        └── BinaryOperator  "+"
            ├── DeclRefExpr  "a"
            └── DeclRefExpr  "b"
```

Los nodos hoja son los valores concretos; los nodos internos son las operaciones o estructuras que los combinan. El análisis semántico anota cada nodo con información de tipos, y luego la generación de código recorre el árbol para producir instrucciones ensamblador.

---

### ¿Qué es el lenguaje ensamblador y qué es un archivo `.s`?

El **lenguaje ensamblador** (assembly) es la representación textual y legible de las instrucciones de máquina de un procesador. Cada instrucción corresponde directamente a una operación elemental del procesador: mover un valor de memoria a un registro, sumar dos registros, saltar a otra posición del programa, etc.

Es el nivel de abstracción más bajo que aún puede leer un humano. A diferencia de C, no hay bucles `for`, funciones con nombre propio ni tipos: todo son registros (`w0`, `x1`...), posiciones de memoria y saltos condicionales.

Un archivo `.s` es simplemente texto con esas instrucciones. Cada arquitectura tiene su propio conjunto de instrucciones (ISA):
- **ARM64** (Apple Silicon, Raspberry Pi): instrucciones como `sub`, `str`, `ldr`, `bl`, `ret`
- **x86-64** (Intel/AMD en Linux y Windows): instrucciones como `mov`, `push`, `call`, `ret`

El código generado es equivalente en ambas, sólo cambia el vocabulario.

### Práctica

```bash
gcc -S programa.c -o programa.s
```

Abrir `programa.s` y explorar su contenido. Es texto legible, aunque de más bajo nivel que C.

```bash
# Ver las primeras líneas
head -25 programa.s
```

Se verá algo como (en arquitectura ARM64 / Apple Silicon):

```asm
    .globl  _sumar              ; símbolo exportado: es visible para el enlazador
_sumar:                         ; etiqueta: marca dónde comienza la función sumar
    sub     sp, sp, #16         ; reserva 16 bytes en la pila (stack)
    str     w0, [sp, #12]       ; guarda el parámetro 'a' en la pila
    str     w1, [sp, #8]        ; guarda el parámetro 'b' en la pila
    ...
    ldr     w8, [sp, #12]       ; carga 'a' en el registro w8
    ldr     w9, [sp, #8]        ; carga 'b' en el registro w9
    add     w0, w8, w9          ; w0 = w8 + w9  (w0 es el registro de retorno)
    ret                         ; retorna al llamador
```

> En x86-64 (Linux/Windows) el ensamblador generado tendrá instrucciones distintas (`mov`, `add`, `ret`) pero el concepto es el mismo.

#### Observación — Las funciones externas aparecen como llamadas sin definición

Buscar referencias a funciones externas en el ensamblador:
```bash
grep "area_circulo\|factorial\|printf" programa.s
```

Aparecen como instrucciones de llamada (por ejemplo `bl _area_circulo`), pero **no existe ningún bloque `_area_circulo:` con su código**. El compilador sabe que esas funciones existen (las declaró el encabezado), pero no tiene su cuerpo —eso lo resuelve el enlazador.

#### Errores detectados en esta etapa

Introducir deliberadamente un error semántico. Editar `programa.c` y cambiar:
```c
resultado = sumar(3, 4);
```
por:
```c
resultado = sumar(3, 4, 5);   /* demasiados argumentos */
```
Al intentar compilar:
```bash
gcc -S programa.c   # genera un error de tipos/argumentos
```
El compilador lo detecta porque ya tiene la declaración de `sumar` y puede verificar la firma. **Restaurar** el código original antes de continuar.

---

## Etapa 3 — Ensamblado

### Concepto teórico

El **ensamblador** (`as`) traduce el archivo `.s` (texto) a **código objeto** (binario). El resultado es un archivo `.o` en un formato binario estructurado:

- **ELF** en Linux
- **Mach-O** en macOS
- **COFF/PE** en Windows

Todos estos formatos tienen la misma idea: son contenedores binarios que almacenan varias secciones:

| Sección | Contenido |
|---|---|
| `.text` | Las instrucciones de máquina de las funciones |
| `.data` | Variables globales con valor inicial |
| `.bss` | Variables globales inicializadas en cero |
| Tabla de símbolos | Lista de nombres (funciones/variables) que este archivo define o necesita |
| Tabla de reubicación | Lista de posiciones que el enlazador deberá corregir cuando asigne direcciones finales |

#### ¿Qué son los símbolos indefinidos (`U`)?

Un archivo `.o` puede hacer referencia a funciones o variables que **no están en él**: viven en otro `.o` o en una biblioteca. Esas referencias se registran en la tabla de símbolos con el tipo `U` (Undefined = indefinido), lo que significa: *"sé que esto existe y lo necesito, pero no sé dónde está todavía"*.

Esto es intencional: permite compilar cada archivo `.c` de forma independiente, y luego unir todo en el enlazado. Si los `.o` no pudieran tener referencias indefinidas, habría que compilar todos los archivos juntos siempre, lo que sería muy costoso en proyectos grandes.

#### Herramienta: `nm`

`nm` (Name Map) es una utilidad que **lista la tabla de símbolos** de un archivo objeto o ejecutable. Para cada símbolo muestra:

```
<dirección>  <tipo>  <nombre>
```

Los tipos más comunes son:

| Tipo | Significado |
|---|---|
| `T` | Definido en la sección de código (Text) — una función |
| `D` | Definido en la sección de datos inicializados (Data) — variable global con valor |
| `S` | Definido en sección de datos del sistema (similar a D en macOS) |
| `B` | Definido en la sección BSS — variable global sin inicializar |
| `U` | **Indefinido** (Undefined) — se necesita pero no se encontró aquí |

`nm` es útil para diagnosticar errores de enlazado: si el enlazador dice *"símbolo no encontrado"*, `nm` permite ver exactamente en qué `.o` se necesita y en cuál debería estar definido.

### Práctica

Generar los archivos objeto de ambas unidades de traducción:

```bash
gcc -c programa.c  -o programa.o
gcc -c matematica.c -o matematica.o
```

#### Observar la tabla de símbolos

```bash
nm programa.o
```

Salida esperada (simplificada):

```
                 U _area_circulo      ← INDEFINIDO: lo define matematica.o
                 U _factorial         ← INDEFINIDO: lo define matematica.o
000000000000018c T _imprimir_separador ← DEFINIDO en este archivo (T = texto/código)
0000000000000300 S _llamadas          ← DEFINIDO: variable global
0000000000000030 T _main              ← DEFINIDO: función main
                 U _printf            ← INDEFINIDO: lo define libc
```

```bash
nm matematica.o
```

```
0000000000000000 T _area_circulo      ← DEFINIDO aquí
0000000000000034 T _factorial         ← DEFINIDO aquí
```

> **Clave:** `programa.o` declara que *necesita* `_area_circulo` y `_factorial` (símbolo `U`). `matematica.o` los *define* (símbolo `T`). El enlazador los conectará.

#### ¿Por qué no se puede ejecutar todavía?

```bash
./programa.o   # Error: no es un ejecutable, es un archivo objeto
```

Un `.o` no es ejecutable por dos razones:

1. Tiene **símbolos indefinidos** — las funciones externas aún no están resueltas.
2. Le falta la **infraestructura de inicio del proceso**: cuando el sistema operativo lanza un ejecutable, no llama directamente a `main()`. Antes ejecuta código de inicialización (`crt0`, "C Runtime 0") que configura el entorno de C (argumentos, variables de entorno, memoria), llama a `main()`, y luego llama a `exit()` con el valor retornado. Ese código lo aporta `libc` durante el enlazado.

---

## Etapa 4 — Enlazado

### Concepto teórico

El **enlazador** (linker, `ld`) combina uno o más archivos `.o` y resuelve todos los símbolos indefinidos. Para eso:

1. Reúne todos los archivos objeto especificados.
2. Busca en las **bibliotecas** los símbolos que aún faltan.
3. **Relocaliza** las direcciones: asigna direcciones de memoria definitivas a cada función y variable.
4. Agrega el código de inicio del proceso (`crt0`/`crt1`).
5. Produce el ejecutable final.

```
programa.o  ──┐
              ├──► enlazador ──► programa (ejecutable)
matematica.o ─┤
              │
libc.dylib  ──┘  (contiene printf, exit, crt1, malloc, etc.)
```

#### ¿Qué es una biblioteca?

Una **biblioteca** (library) es una colección de funciones precompiladas, empaquetadas en un único archivo, listas para ser reutilizadas por cualquier programa. Existen dos tipos:

**Biblioteca estática** (`.a` en Linux/macOS, `.lib` en Windows):
- Es un archivo que contiene varios `.o` agrupados.
- El enlazador **copia** el código de las funciones que se usan directamente dentro del ejecutable.
- El ejecutable resultante no tiene dependencias externas en tiempo de ejecución.
- Desventaja: el ejecutable es más grande; si la biblioteca se actualiza, hay que recompilar.

**Biblioteca dinámica** (`.so` en Linux, `.dylib` en macOS, `.dll` en Windows):
- El ejecutable sólo guarda una **referencia** al nombre de la biblioteca.
- El código real se carga en memoria en tiempo de ejecución, cuando se lanza el programa.
- Ventaja: menor tamaño del ejecutable; múltiples programas comparten la misma copia en memoria; actualizar la biblioteca no requiere recompilar los programas.
- Desventaja: si la biblioteca no está instalada o tiene una versión incompatible, el programa falla al iniciar.

La biblioteca estándar de C (`libc`) existe en ambas formas. Por defecto, `gcc` usa la versión dinámica.

**Enlazado estático vs dinámico:**

| | Estático | Dinámico |
|---|---|---|
| Las funciones de bibliotecas | se copian en el ejecutable | se cargan en tiempo de ejecución |
| Tamaño del ejecutable | mayor | menor |
| Dependencias en tiempo de ejecución | ninguna | necesita las `.so`/`.dylib` |
| Uso típico | sistemas embebidos, distribución única | aplicaciones de escritorio/servidor |

### Práctica

```bash
gcc programa.o matematica.o -o programa
```

`gcc` actúa aquí como un *driver* que invoca al enlazador real (`ld`) con los parámetros correctos, incluyendo automáticamente `libc`.

#### Verificar que los símbolos se resolvieron

```bash
nm programa | grep -E "sumar|factorial|area|main|llamadas|imprimir"
```

Todos los símbolos que antes eran `U` (indefinidos) ahora tienen direcciones concretas:

```
00000001000006a0 T _area_circulo
0000000100000684 T _imprimir_separador
0000000100008000 S _llamadas
0000000100000528 T _main
00000001000004f8 T _sumar
00000001000006d4 T _factorial
```

#### Verificar qué símbolos siguen siendo indefinidos en el ejecutable

```bash
nm programa | grep "^ *U"
```

Quedan algunos `U` incluso en el ejecutable final. ¿Por qué? Son funciones de la biblioteca dinámica del sistema (`libc.dylib`): como se cargan en tiempo de ejecución, el enlazador no las copia, sólo deja registrado su nombre para que el **cargador dinámico** (`dyld`/`ld.so`) las resuelva cuando el programa se ejecute.

#### Ejecutar

```bash
./programa
```

---

## Bonus: inspeccionar las fases internas

### ¿Qué es Clang?

**Clang** es un compilador de C/C++ de código abierto, desarrollado como parte del proyecto **LLVM**. Es el compilador por defecto en macOS (lo instala Xcode Command Line Tools) y compite directamente con GCC en Linux.

Desde el punto de vista del usuario, Clang y GCC son intercambiables: aceptan los mismos flags (`-E`, `-S`, `-c`, `-Wall`, `-DNOMBRE`, etc.) y producen ejecutables equivalentes. La diferencia está en la arquitectura interna: Clang está diseñado con una separación más clara entre fases y expone su funcionamiento interno a través de flags especiales (`-Xclang`), lo que lo hace especialmente útil para estudiar el proceso de compilación.

**LLVM** (Low Level Virtual Machine) es la infraestructura de compilación sobre la que Clang se construye. GCC y Clang son los *frontends* (analizan C y producen una representación intermedia); LLVM es el *backend* (optimiza y genera código de máquina).

```
Código C
   │
   ▼
Clang (frontend)  →  LLVM IR (representación intermedia)  →  LLVM (backend)  →  código máquina
```

Para este laboratorio, lo relevante es que Clang permite observar los tokens y el AST que GCC produce internamente pero no muestra.

---

GCC fusiona internamente el análisis léxico, sintáctico y semántico sin exponer productos intermedios separados. Con Clang podemos hacer visible cada fase.

### Fase léxica — observar los tokens

El analizador léxico convierte la secuencia de caracteres del fuente en una secuencia de tokens. Ejecutar:

```bash
# Mostrar sólo los tokens que provienen de programa.c (no de los headers del sistema)
clang -Xclang -dump-tokens programa.c 2>&1 | grep "programa.c"
```

Cada línea de la salida describe un token con tres datos: su **clase** (qué tipo de token es), su **lexema** (el texto exacto), y su **posición** en el fuente (archivo:línea:columna).

Fragmento de la salida para la función `sumar`:

```
int 'int'          Loc=<programa.c:44:1>   ← palabra clave
identifier 'sumar' Loc=<programa.c:44:5>   ← identificador
l_paren '('        Loc=<programa.c:44:10>  ← delimitador
int 'int'          Loc=<programa.c:44:11>  ← palabra clave
identifier 'a'     Loc=<programa.c:44:15>  ← identificador
comma ','          Loc=<programa.c:44:16>  ← puntuador
...
plusplus '++'      Loc=<programa.c:45:13>  ← operador
return 'return'    Loc=<programa.c:46:5>   ← palabra clave
plus '+'           Loc=<programa.c:46:14>  ← operador
```

Nótese que `int` y `return` son **palabras clave** (reservadas por el lenguaje), mientras que `sumar`, `a`, `b` son **identificadores** (nombres definidos por el programador). El scanner los distingue porque las palabras clave están listadas internamente; cualquier otro nombre válido es un identificador.

También se puede ver que los **comentarios y espacios en blanco no aparecen**: ya fueron eliminados en el preprocesamiento.

> `programa.c` produce ~188 tokens (sin contar los de los headers incluidos). Comparar con las ~1802 líneas del `.i` que incluye todo `stdio.h`.

### Fase sintáctica y semántica — observar el AST

Una vez que el parser tiene la secuencia de tokens, construye el AST verificando que los tokens respetan la gramática de C. El análisis semántico luego anota cada nodo con su tipo.

```bash
# Ver el AST completo de programa.c (salida extensa)
clang -Xclang -ast-dump programa.c 2>/dev/null | grep -A 20 "FunctionDecl.*sumar"
```

Salida real del AST para `sumar`:

```
FunctionDecl sumar 'int (int, int)'      ← función: nombre, tipo de retorno y parámetros
├─ParmVarDecl a 'int'                    ← parámetro a de tipo int
├─ParmVarDecl b 'int'                    ← parámetro b de tipo int
└─CompoundStmt                           ← cuerpo de la función { ... }
  ├─UnaryOperator postfix '++'           ← expresión: llamadas++
  │ └─DeclRefExpr 'llamadas' 'int'       ←   referencia a la variable llamadas (tipo int)
  └─ReturnStmt                           ← sentencia: return ...
    └─BinaryOperator 'int' '+'           ←   operación suma, resultado de tipo int
      ├─ImplicitCastExpr → DeclRefExpr 'a' 'int'   ← operando izquierdo: a
      └─ImplicitCastExpr → DeclRefExpr 'b' 'int'   ← operando derecho: b
```

Puntos clave a observar:

- El **árbol refleja la jerarquía**: la función contiene un bloque, el bloque contiene sentencias, las sentencias contienen expresiones, las expresiones contienen subexpresiones.
- Cada nodo tiene su **tipo anotado** (`'int'`, `'double'`, etc.) — esto lo hizo el análisis semántico.
- `ImplicitCastExpr` son conversiones de tipo que el programador no escribió pero el compilador insertó automáticamente. Están en el AST aunque sean invisibles en el código fuente.
- Los **paréntesis, llaves y puntos y coma no aparecen en el AST**: fueron necesarios para parsear la estructura, pero una vez construido el árbol ya no hacen falta. Por eso se llama "abstracto": abstrae los detalles de notación y conserva sólo la estructura semántica.

> **Importante:** GCC y Clang son compiladores de producción, y estas fases ocurren en fracciones de segundo de forma integrada. Lo que importa es entender que **estas fases existen y operan en secuencia**, y que cada una detecta un tipo distinto de error (léxico → sintáctico → semántico).

---

## Flujo completo — Resumen de comandos

```bash
# Todas las etapas de golpe (lo que hace gcc por defecto):
gcc -Wall programa.c matematica.c -o programa

# O paso a paso:
gcc -E  programa.c          -o programa.i    # 1. Preprocesamiento
gcc -S  programa.c          -o programa.s    # 2. Compilación (hasta ensamblador)
gcc -c  programa.c          -o programa.o    # 3. Ensamblado (objeto)
gcc -c  matematica.c        -o matematica.o  # 3. Ensamblado (objeto)
gcc     programa.o matematica.o -o programa  # 4. Enlazado

# Compilar con modo debug activado:
gcc -Wall -DDEBUG programa.c matematica.c -o programa_debug
./programa_debug   # verá los mensajes [DEBUG]

# Inspeccionar fases internas (requiere clang):
clang -Xclang -dump-tokens programa.c 2>&1 | grep "programa.c"   # tokens
clang -Xclang -ast-dump    programa.c 2>/dev/null | grep -A 20 "FunctionDecl.*sumar"  # AST
```

---

## Tabla de extensiones de archivo

| Extensión | Contenido | Etapa que lo produce |
|---|---|---|
| `.c` | Código fuente C | (escrito por el programador) |
| `.h` | Encabezado C | (escrito por el programador) |
| `.i` | C preprocesado (texto) | Preprocesador (`-E`) |
| `.s` | Ensamblador (texto) | Compilador (`-S`) |
| `.o` | Código objeto (binario) | Ensamblador (`-c`) |
| `.a` | Biblioteca estática (colección de `.o`) | Herramienta `ar` |
| `.so` / `.dylib` | Biblioteca dinámica | Enlazador con `-shared` |
| (sin ext. / `.exe`) | Ejecutable (binario) | Enlazador |

---

## Ejercicios

### Ejercicio 1 — Explorar el preprocesamiento

a. Buscar en `programa.i` dónde aparece la expansión de la macro `MAX(7, 12)` y verificar cómo quedó.

b. ¿Aparece alguna mención al nombre `CUADRADO` en `programa.i`? ¿Por qué sí o por qué no?

c. Buscar el comienzo de la declaración de `printf` en `programa.i`. ¿En qué línea aparece? ¿De qué archivo provino? (Pista: buscar las líneas que comienzan con `#` en el `.i` — son marcadores que indica de qué archivo original proviene cada bloque.)

### Ejercicio 2 — Provocar errores

a. **Error léxico:** editar `programa.c` y escribir una cadena sin cerrar: `printf("hola`. Intentar compilar. ¿En qué etapa falla y qué dice el mensaje?

b. **Error sintáctico:** quitar un `;` al final de una declaración de variable. ¿Qué dice el compilador?

c. **Error semántico:** declarar `int resultado;` y luego asignarle `resultado = area_circulo(5.0);`. ¿Qué error genera? ¿Por qué es semántico y no sintáctico?

d. **Error de enlazado:** comentar toda la función `area_circulo` en `matematica.c` y recompilar **sólo** el objeto (`gcc -c matematica.c`). ¿Falla? Ahora intentar enlazar. ¿Cuándo falla y cuál es el mensaje?

### Ejercicio 3 — Agregar una función

a. Agregar en `matematica.h` el prototipo:
```c
double potencia(double base, int exp);
```

b. Implementar la función en `matematica.c` (sin usar `<math.h>`).

c. Llamarla desde `main()` en `programa.c`.

d. Compilar paso a paso y verificar con `nm` que el nuevo símbolo aparece correctamente en cada etapa.

### Ejercicio 4 — Investigación

a. ¿Qué diferencia hay entre un símbolo con tipo `T` y uno con tipo `D` en la salida de `nm`?

b. Buscar con `nm` los símbolos de tipo `U` que quedan en el ejecutable final. ¿Qué son? ¿Por qué siguen siendo indefinidos?
```bash
nm programa | grep "^ *U"
```

c. ¿Qué hace la opción `-Wall` en gcc? Intentar compilar sin ella y con ella introduciendo una variable declarada pero no usada. ¿Qué cambia?

d. ¿Cómo se puede ver qué bibliotecas dinámicas necesita un ejecutable? Investigar el comando `otool -L programa` (macOS) o `ldd programa` (Linux).

---

## Cómo entregar este laboratorio

### Qué hay que commitear

Al finalizar el laboratorio el repositorio debe contener estos archivos nuevos (los fuentes `programa.c`, `matematica.c`, `matematica.h` y `laboratorio.md` ya estaban y no deben modificarse):

| Archivo | Cómo se genera | Para qué sirve en la entrega |
|---|---|---|
| `programa.i` | `gcc -E programa.c -o programa.i` | Evidencia del preprocesamiento |
| `programa.s` | `gcc -S programa.c -o programa.s` | Evidencia de la compilación a ensamblador |
| `salidas/nm_programa_o.txt` | `nm programa.o > salidas/nm_programa_o.txt` | Tabla de símbolos antes de enlazar |
| `salidas/nm_ejecutable.txt` | `nm programa > salidas/nm_ejecutable.txt` | Tabla de símbolos después de enlazar |
| `salidas/salida_debug.txt` | compilar con `-DDEBUG` y redirigir salida | Evidencia de compilación condicional |
| `respuestas.md` | completado a mano | Respuestas conceptuales |

**No commitear:** `programa.o`, `matematica.o`, ni ejecutables (`programa`, `programa_debug`). El `.gitignore` ya los excluye automáticamente.

---

### Paso a paso: clonar, trabajar, entregar

#### Paso 1 — Aceptar el assignment y clonar

1. Hacer clic en el link del assignment que publicó el docente en GitHub Classroom.
2. GitHub crea automáticamente un repositorio personal con los archivos del laboratorio.
3. En la página del repositorio recién creado, hacer clic en el botón verde **"Code"** y copiar la URL.
4. Abrir una terminal y ejecutar:

```bash
git clone <pegar-la-URL-aquí>
```

Por ejemplo:

```bash
git clone https://github.com/utn-sintaxis/lab-compilacion-juan-perez
```

5. Entrar a la carpeta del repositorio:

```bash
cd lab-compilacion-juan-perez
```

Verificar que están los archivos del laboratorio:

```bash
ls
# debe mostrar: laboratorio.md  matematica.c  matematica.h  programa.c  respuestas.md
```

---

#### Paso 2 — Crear una rama de trabajo

En git, una **rama** (branch) es una línea de trabajo separada. No se trabaja directamente sobre `main` — se crea una rama propia y al final se abre un Pull Request para que el docente revise.

```bash
git checkout -b entrega
```

Esto crea la rama `entrega` y cambia a ella. Verificar con:

```bash
git branch
# debe mostrar:
#   main
# * entrega    ← el asterisco indica la rama actual
```

---

#### Paso 3 — Crear la carpeta de salidas

```bash
mkdir salidas
```

---

#### Paso 4 — Ejecutar cada etapa y guardar los resultados

Seguir la guía del laboratorio y al terminar cada etapa, ejecutar los comandos de captura:

**Etapa 1 — Preprocesamiento:**
```bash
gcc -E programa.c -o programa.i
```

**Etapa 2 — Compilación a ensamblador:**
```bash
gcc -S programa.c -o programa.s
```

**Etapa 3 — Ensamblado y tabla de símbolos:**
```bash
gcc -c programa.c  -o programa.o
gcc -c matematica.c -o matematica.o
nm programa.o > salidas/nm_programa_o.txt
```

**Etapa 4 — Enlazado y tabla de símbolos final:**
```bash
gcc programa.o matematica.o -o programa
nm programa > salidas/nm_ejecutable.txt
```

**Compilación condicional con DEBUG:**
```bash
gcc -DDEBUG programa.c matematica.c -o programa_debug
./programa_debug > salidas/salida_debug.txt
```

---

#### Paso 5 — Completar `respuestas.md`

Abrir el archivo `respuestas.md` con cualquier editor de texto y responder cada pregunta. Las respuestas deben incluir la salida real de los comandos que ejecutaron.

---

#### Paso 6 — Commitear los archivos generados

En git, **commitear** significa guardar un punto de control con los cambios actuales. Primero se agregan los archivos al "área de preparación" con `git add`, luego se crea el commit con `git commit`.

Primero, verificar qué archivos nuevos existen:

```bash
git status
```

La salida mostrará algo como:

```
On branch entrega
Untracked files:
  (use "git add <file>..." to include in what will be committed)
        programa.i
        programa.s
        salidas/
        respuestas.md   ← aparece como modified porque ya existía
```

Agregar y commitear los archivos de a uno por etapa (así queda un historial claro):

```bash
# Etapa 1
git add programa.i
git commit -m "Agrego programa.i - salida del preprocesamiento"

# Etapa 2
git add programa.s
git commit -m "Agrego programa.s - codigo ensamblador generado"

# Etapas 3 y 4 - tablas de simbolos
git add salidas/nm_programa_o.txt salidas/nm_ejecutable.txt
git commit -m "Agrego tablas de simbolos antes y despues del enlazado"

# Compilacion condicional
git add salidas/salida_debug.txt
git commit -m "Agrego salida del programa compilado con -DDEBUG"

# Respuestas
git add respuestas.md
git commit -m "Completo respuestas del laboratorio"
```

Verificar que los commits se guardaron:

```bash
git log --oneline
# debe mostrar los 5 commits recién creados
```

> **Importante:** `programa.o` y los ejecutables **no deben aparecer** en `git status`. Si aparecen, revisar que el `.gitignore` esté en el repositorio. Si aun así aparecen, **no ejecutar `git add .`** — agregar cada archivo por nombre.

---

#### Paso 7 — Subir la rama a GitHub

```bash
git push -u origin entrega
```

La primera vez pedirá usuario y contraseña (o token) de GitHub. Después de esto, la rama `entrega` existe tanto local como en GitHub.

---

#### Paso 8 — Abrir el Pull Request

1. Ir al repositorio en GitHub (la URL que copiaron en el Paso 1).
2. GitHub mostrará un banner amarillo: **"entrega had recent pushes — Compare & pull request"**. Hacer clic en ese botón.
3. En la página del Pull Request:
   - **Title:** `Entrega laboratorio - [Nombre y Apellido]`
   - **Description:** pueden dejar un comentario breve si quieren
   - Verificar que la base sea `main` ← `entrega`
4. Hacer clic en **"Create pull request"**.

---

#### Paso 9 — Verificar los checks automáticos

Inmediatamente después de crear el PR, GitHub Actions ejecuta las verificaciones automáticas. En la pestaña **"Checks"** del PR se puede ver el resultado de cada una.

- ✅ **Verde** = el check pasó
- ❌ **Rojo** = el check falló

Si algún check falla, se puede corregir y volver a subir sin necesidad de crear un nuevo PR:

```bash
# Corregir lo que sea necesario...
git add <archivo-corregido>
git commit -m "Corrijo: <descripción del problema>"
git push
```

Los checks se vuelven a ejecutar solos con cada push a la misma rama.

---

### Qué verifican los checks automáticos

Los checks son comandos de shell que el servidor de GitHub ejecuta sobre los archivos commiteados. Un check **pasa** si el comando termina sin error (código de salida 0), **falla** si termina con error.

Los checks se dividen en dos grupos:

**Grupo A — Archivos generados** (verifican que ejecutaste cada etapa):

| # | Qué verifica | Comando que usa el servidor |
|---|---|---|
| 1 | `programa.i` existe | `test -f programa.i` |
| 2 | No hay `#define` en `.i` (macros expandidas) | `! grep -q '^#define' programa.i` |
| 3 | `VERSION` expandido a `"1.0"` | `grep -q '"1\.0"' programa.i` |
| 4 | `CUADRADO(LIMITE)` expandido a `((5) * (5))` | `grep -qF '((5) * (5))' programa.i` |
| 5 | Comentarios eliminados | `! grep -q 'Archivo fuente principal' programa.i` |
| 6 | `.i` tiene >500 líneas | `test $(wc -l < programa.i) -gt 500` |
| 7 | `programa.s` existe | `test -f programa.s` |
| 8 | `sumar` definida en `.s` | `grep -qE '^(sumar\|_sumar):' programa.s` |
| 9 | `area_circulo` llamada pero no definida en `.s` | grep llama + grep no define |
| 10 | `nm_programa_o.txt` tiene `area_circulo` como `U` | `grep -qE 'U.*(area_circulo)' ...` |
| 11 | `nm_ejecutable.txt` tiene `area_circulo` como `T` | `grep -qE 'T.*(area_circulo)' ...` |
| 12 | `salida_debug.txt` contiene `[DEBUG]` | `grep -q '\[DEBUG\]' ...` |
| 13 | Los fuentes compilan y producen `factorial(5) = 120` | compila + corre en el servidor |
| 14 | `programa.o` no está commiteado | `! test -f programa.o` |

**Grupo R — Respuestas cerradas en `respuestas.md`** (verifican que respondiste correctamente):

| # | Clave que se busca | Respuesta correcta | Qué concepto evalúa |
|---|---|---|---|
| R1 | `LINEAS_I=` | número de 3-4 dígitos | expansión de `#include` |
| R2 | `CUADRADO_EN_I=` | `NO` | expansión de macros |
| R3 | `NOMBRE_MACRO_VERSION=` | `VERSION` | identificar macros en el fuente |
| R4 | `COMENTARIOS_EN_I=` | `NO` | eliminación de comentarios |
| R5 | `DEBUG_ACTIVA_CODIGO=` | `SI` | compilación condicional |
| R6 | `AREA_EN_S=` | `LLAMADA` | compilación separada |
| R7 | `LLAMADAS_EN_S=` | `SI` | variables globales en ensamblador |
| R8 | `TIPO_AREA_EN_O=` | `U` | símbolo indefinido en objeto |
| R9 | `ETAPA_QUE_RESUELVE=` | `ENLAZADO` | rol del linker |
| R10 | `EJECUTABLE_O=` | `NO` | por qué `.o` no es ejecutable |
| R11 | `TIPO_AREA_ENLAZADO=` | `T` | resolución de símbolos |
| R12 | `SIMBOLOS_U_FINAL=` | `SI` | bibliotecas dinámicas |
| R13 | `FACTORIAL_5=` | `120` | verificación de ejecución |

El servidor busca exactamente `CLAVE=VALOR` al inicio de una línea. Si pusiste un espacio, una comilla o una minúscula donde va mayúscula, el check falla.

> **Revisión manual:** las preguntas abiertas (`> **R:**`) no se verifican automáticamente. El docente las lee en el diff del Pull Request y puede dejar comentarios en líneas específicas.

---

## Referencia rápida — Opciones de GCC usadas

| Opción | Efecto |
|---|---|
| `-E` | Detener tras el preprocesamiento |
| `-S` | Detener tras la compilación (genera `.s`) |
| `-c` | Detener tras el ensamblado (genera `.o`) |
| `-o archivo` | Nombre del archivo de salida |
| `-Wall` | Activar todos los avisos (warnings) importantes |
| `-DNOMBRE` | Definir la macro `NOMBRE` (equivale a `#define NOMBRE 1`) |
| `-DNOMBRE=valor` | Definir `NOMBRE` con un valor específico |
| `-g` | Incluir información de depuración (para usar con `gdb`) |
| `-O2` | Optimización nivel 2 |
| `-static` | Forzar enlazado estático |

## Referencia rápida — Herramientas de inspección

| Herramienta | Uso | Ejemplo |
|---|---|---|
| `wc -l` | Contar líneas de un archivo | `wc -l programa.i` |
| `grep` | Buscar patrón en archivo | `grep "printf" programa.s` |
| `head -N` | Ver primeras N líneas | `head -20 programa.s` |
| `nm` | Tabla de símbolos de `.o` o ejecutable | `nm programa.o` |
| `clang -Xclang -dump-tokens` | Análisis léxico (tokens) | ver sección Bonus |
| `clang -Xclang -ast-dump` | AST (análisis sintáctico+semántico) | ver sección Bonus |
| `otool -L` (macOS) / `ldd` (Linux) | Bibliotecas dinámicas del ejecutable | `otool -L programa` |
