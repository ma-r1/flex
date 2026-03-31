%{
  #include <math.h>
  #include "definiciones.h"
  #include "ts.h"
  #include "errores.h"
%}


  /*DEFINICIONES REGULARES*/
  /*Se permite el uso de _ en los números e identificadores.*/
DIGITO    [0-9_]
DIGITOBIN [01_]
ALFANUM   [a-zA-Z_][a-zA-Z0-9_]*
EXPONENTE [eE][+-]?

  /*OPCIONES DE FLEX*/
  /*yylineno hace que flex cuente automáticamente los saltos de línea*/
%option yylineno
  /*stack activa la pila de estados interna, que se usa para analizar los comentarios anidados*/
%option stack

  /*ESTADOS EXCLUSIVOS*/
  /*Son condiciones de arranque que apagan las reglas normales*/
%x COMENTARIO_ANIDADO
%x COMENTARIO_MULTILINEA


%%


  /*Ignora espacios en blanco*/
[ \t\n]+                {}

  /*Inserta IDs nuevos en la ts o devuelve el componente léxico del ID o keyword en la ts*/
{ALFANUM} {
  int buscar = buscar_ts(yytext);
  if (buscar == -1) {
    insertar_ts(yytext);
    return ID;
  }
  return buscar;
}

  /*Números enteros*/
(0b|0B){DIGITOBIN}+     {return ENTERO;}
{DIGITO}+               {return ENTERO;}

  /*Números decimales*/
{DIGITO}+"."{DIGITO}+({EXPONENTE}{DIGITO}+)?   {return DECIMAL;}
"."{DIGITO}+({EXPONENTE}{DIGITO}+)?            {return DECIMAL;}
{DIGITO}+({EXPONENTE}{DIGITO}+)                {return DECIMAL;} 

  /*Operadores de varios caracteres*/
"=="                    {return DOBLEIGUAL;}
"+="                    {return MASIGUAL;}
"++"                    {return MASMAS;}

  /*El componente léxico de los operadores de un único caracter es el código ascii de dicho caracter*/
[;()[\]{},\-*<>\\=+/\.] {return yytext[0];}

  /*Strings, considera la posibilidad de un salto de línea o EOF antes de encontrar las comillas de cierre*/
\"([^"\n]|"\\\"")*\"    {return STRING;}
\"([^"\n]|"\\\"")*\n    {alex_error_string_sin_cerrar();}
\"([^"\n]|"\\\"")*      {alex_error_string_sin_cerrar(); return 0;}

  /*Comentarios de una línea*/
"//".*                  {}

  /*Comentarios multilínea, considera la posibilidad de un EOF antes de encontrar el cierre del comentario*/
"/*"                            {BEGIN(COMENTARIO_MULTILINEA);}
<COMENTARIO_MULTILINEA>"*/"     {BEGIN(INITIAL);}
<COMENTARIO_MULTILINEA>[^*]+    {/*Consume cualquier caracter que no sea un * */}
<COMENTARIO_MULTILINEA>"*"      {/*Consume * no seguidos de / */}
<COMENTARIO_MULTILINEA><<EOF>>  {alex_error_comentario_multilinea(); return 0;}

  /*Comentarios anidados usando la pila de estados, considera la posibilidad de un EOF antes de encontrar el cierre total del comentario*/
"/+"                        {yy_push_state(COMENTARIO_ANIDADO);}
<COMENTARIO_ANIDADO>"/+"    {yy_push_state(COMENTARIO_ANIDADO);}
<COMENTARIO_ANIDADO>"+/"    {yy_pop_state();}
<COMENTARIO_ANIDADO>[^+/]+   {/*Consume cualquier caracter que no sesa un +*/}
<COMENTARIO_ANIDADO>"+"     {/*Consume +s no seguidos de / (no cierran un nivel)*/}
<COMENTARIO_ANIDADO>"/"     {/*Consume /s no precedidos de + (no abren un nuevo nivel)*/}
<COMENTARIO_ANIDADO><<EOF>> {
  alex_error_comentario_anidado();
  yy_pop_state();
  return 0;
}

  /*Si no se activa ninguna otra regla, se lanza un error de caracter desconocido*/
.                       {alex_error_caracter(yytext[0]);}

%%
