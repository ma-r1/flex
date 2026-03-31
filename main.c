#include <stdio.h>
#include <stdlib.h>

#include "asin.h"
#include "errores.h"
#include "ts.h"

extern FILE * yyin;
extern int yylex_destroy(void);

int main(int argc, char * argv[]) {
  inicializar_ts();
  imprimir_ts();

  //Si sólo hay un argumento (el nombre del programa), el fichero de entrada es regression.d.
  //En caso contrario, el fichero de entrada es el argumento especificado
  char *ruta = (argc < 2) ? "./regression.d" : argv[1];
  yyin = fopen(ruta, "r");
  if (yyin == NULL) {
    error_archivo_no_abierto(ruta);
  }

  //Bucle principal
  imprimir_componentes_lexicos();

  imprimir_ts();
  if(fclose(yyin)!=0){
    error_archivo_no_cerrado();
  }
  yylex_destroy();
  destruir_ts();
  return 0;
}


