#include "symbol_table.h"
#include <string.h>

#define RED   "\x1b[31m"
#define GRN   "\x1b[32m"
#define YEL   "\x1b[33m"
#define BLU   "\x1b[34m"
#define MAG   "\x1b[35m"
#define CYN   "\x1b[36m"
#define RESET "\x1b[0m"

#define NUM_OF_LIB_FUNC 12

void insert_lib_functions(SymbolTable * symTable){

    char lib_functions[NUM_OF_LIB_FUNC][19] = {
        "print",
        "input",
        "objectmemberkeys",
        "objecttotalmembers",
        "objectcopy",
        "totalarguments",
        "argument",
        "typeof",
        "strtonum",
        "sqrt",
        "cos",
        "sin"
    };

    for(int i = 0; i < NUM_OF_LIB_FUNC; i++) {   
        char* name     = strndup(lib_functions[i], strlen(lib_functions[i])+1);    
        Symbol* symbol = symbol_create(name, 0, 0, LIBFUNC, 0);
        symbol_table_insert(symTable, symbol);
    }
}

//Move
const char* str_type(enum SymbolType type){
    switch (type){
        case USERFUNC:  return "user function";
        case LIBFUNC:   return "library function";
        case GLOBAL:    return "global variable";
        case FORMAL:    return "formal variable";
        case _LOCAL:    return "local variable";    
        
        default:       return "INVALID";
    }
}

void symbol_table_print(SymbolTable* symTable){

    for(int i = 0; i < symTable->scope_size; i++){

        Symbol* current_symbol = symTable->first_symbol_scopes[i];
        if(current_symbol == NULL) continue;

        printf("-------- Scope #%d --------\n", i);

        while(current_symbol != NULL){
            printf("\"%s\"[%s] (line: %d) (scope %d)\n", current_symbol->name, str_type(current_symbol->symbol_type), current_symbol->line, current_symbol->scope);
            current_symbol = current_symbol->next_symbol_of_same_scope;
        }
    }
    printf("\n");
}