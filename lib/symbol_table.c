#include "symbol_table.h"

#define INITIAL_SYMBOL_TABLE_CAPACITY 32
#define INITIAL_SCOPE_CAPACITY 16

SymbolTable* symbol_table_create() {
    SymbolTable* symbol_table = (SymbolTable*)malloc(sizeof(SymbolTable));
    symbol_table->size        = INITIAL_SYMBOL_TABLE_CAPACITY;
    symbol_table->buckets     = (SymbolTableBucket**)malloc(sizeof(SymbolTableBucket*) * INITIAL_SYMBOL_TABLE_CAPACITY);
    symbol_table->first_symbol_scopes = hash_table_create(INITIAL_SCOPE_CAPACITY);
    symbol_table->last_symbol_scopes  = hash_table_create(INITIAL_SCOPE_CAPACITY);

    for(int i = 0; i < INITIAL_SYMBOL_TABLE_CAPACITY; i++) {
        symbol_table->buckets[i] = NULL;
    }

    for(int i = 0; i < INITIAL_SCOPE_CAPACITY; i++) {
        hash_table_insert(symbol_table->first_symbol_scopes, i, NULL);
        hash_table_insert(symbol_table->last_symbol_scopes,  i, NULL);
    }

    return symbol_table;
}

void symbol_table_destroy(SymbolTable* symbol_table) {
    for(int i = 0; i < symbol_table->size; i++) {
        if(symbol_table->buckets[i] != NULL) {
            free_linked_list(symbol_table->buckets[i]->symbol_list);
            free(symbol_table->buckets[i]);
        }
    }

    free(symbol_table->buckets);
    free(symbol_table);
}

void symbol_table_insert(SymbolTable* symbol_table, Symbol* symbol) {
    unsigned int index = hash_function(symbol->name, symbol_table->size);

    if( symbol_table->buckets[index] == NULL) {
        symbol_table->buckets[index] = (SymbolTableBucket*)malloc(sizeof(SymbolTableBucket));
        symbol_table->buckets[index]->symbol_list = create_linked_list();
    }

    unsigned int scope = symbol->scope;
    if(symbol_table_get_first_symbol_of_scope(symbol_table, scope) == NULL) {
        symbol_table->first_symbol_scopes[scope] = symbol;
    }
    update_last_symbol_of_scope(symbol_table, symbol);

    insert_at_the_end_to_linked_list(symbol_table->buckets[index]->symbol_list, symbol);
}

SymbolTableBucket* symbol_table_lookup(SymbolTable* symbol_table, const char* symbol, unsigned int scope) {
    Symbol** first_symbol_of_scope = symbol_table_get_first_symbol_of_scope(symbol_table, scope);

    if(first_symbol_of_scope != NULL) {
        Symbol* current_symbol = *first_symbol_of_scope;

        while(current_symbol != NULL) {
            if(current_symbol->is_active && strcmp(current_symbol->name, symbol) == 0) {
                return current_symbol;
            }

            current_symbol = current_symbol->next_symbol_of_same_scope;
        }
    }

    return NULL;
}

void symbol_table_hide(SymbolTable* symbol_table, unsigned int scope) {
    Symbol** first_symbol_of_scope = symbol_table_get_first_symbol_of_scope(symbol_table, scope);

    if(first_symbol_of_scope != NULL) {
        Symbol* current_symbol = *first_symbol_of_scope;

        while(current_symbol != NULL) {
            current_symbol->is_active = 0;
            current_symbol = current_symbol->next_symbol_of_same_scope;
        }
    }
}

Symbol* symbol_create(const char* name, unsigned int scope, unsigned int line, int symbol_type, int is_variable) {
    Symbol* symbol = (Symbol*)malloc(sizeof(Symbol));
    
    symbol->is_active   = 1;
    symbol->is_variable = is_variable;
    symbol->name  = name;
    symbol->scope = scope;
    symbol->line  = line;
    symbol->symbol_type = symbol_type;
    symbol->next_symbol_of_same_scope = NULL;

    return symbol;
}

void update_last_symbol_of_scope(SymbolTable* symbol_table, Symbol* symbol) {
    symbol_table->last_symbol_scopes[symbol->scope] = symbol;
}

Symbol* symbol_table_get_last_symbol_of_scope(SymbolTable* symbol_table, unsigned int scope) {
    return symbol_table->last_symbol_scopes[scope];
}

Symbol* symbol_table_get_first_symbol_of_scope(SymbolTable* symbol_table, unsigned int scope) {
    return symbol_table->first_symbol_scopes[scope];
}