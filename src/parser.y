%{
    #include "yacc_util.h"
    #include "manage_symtable.h"
    #include "symbol_table.h"
    #include "scope_space.h"

    #define IS_GLOBAL scope > 0 ? _LOCAL : GLOBAL

    unsigned int scope = 0;
    unsigned int actual_line = 0;
    int anonym_cnt = 0;
    Stack *func_line_stack;
    Stack *scope_offset_stack;
    ScopeStackList *in_function_tail; //we use this "stack" to add a flag for every new scope opening (1 if in function, 0 if not)

    int loop_flag          = 0;
    int return_flag        = 0;
    int normcall_skip      = 0;       // we want to manage_function_call only when a function is called, not when a method is called

    int is_function_block  = 0;  // 0: not in function block, 1: in function block
    int is_function_active = 0;  // 0: not in function, > 0 in function

    Symbol* func_sym;

    //variable offset counters
    extern unsigned int programVarOffset;
    extern unsigned int functionLocalOffset;
    extern unsigned int formalArgOffset;
    extern unsigned int scopeSpaceCounter; //determines current offset
%}

%start program

%union{
    int intVal;
    double realVal;
    char *stringVal;
    struct Symbol *symbolVal;
}

%token <intVal>    INTCONST
%token <realVal>   REALCONST
%token <stringVal> STRING
%token <stringVal> IDENT

%token ASSIGN  "="
%token PLUS    "+"
%token MINUS   "-"
%token MUL     "*" 
%token DIV     "/"
%token MOD     "%"
%token EQ      "=="
%token NEQ     "!="
%token INC     "++"
%token DEC     "--"
%token GT      ">"
%token LT      "<"
%token GTE     ">="
%token LTE     "<=" 
%token LBRACE  "["  
%token RBRACE  "]"
%token LCBRACE "{"
%token RCBRACE "}"
%token LPAR    "("
%token RPAR    ")"
%token SEMI    ";"
%token COMMA   ","
%token COLON   ":"
%token DCOLON  "::"
%token DOT     "."
%token DDOT    ".."

%token AND OR NOT IF ELSE WHILE FOR FUNCTION RETURN BREAK CONTINUE LOCAL TRUE FALSE NIL

%type<stringVal> id_opt com_id_opt lvalue member
%type<intVal>    callsuffix
%type<symbolVal> funcprefix funcdef
%nonassoc LP_ELSE
%nonassoc ELSE

%right ASSIGN
%left OR
%left AND 
%nonassoc EQ NEQ
%nonassoc LT GT LTE GTE
%left PLUS MINUS
%left MUL DIV MOD
%right NOT INC DEC UMINUS
%left DOT DDOT  
%left LBRACE RBRACE 
%left LPAR RPAR 

%%  

program     : stmtList      {fprintf(yyout, MAG "Detected :" RESET"program stmtList \n");}
            ;   

stmt        : expr ";"      {fprintf(yyout, MAG "Detected :" RESET"expr;"CYN" ->"RESET" stmt \n");}
            | ifstmt        {fprintf(yyout, MAG "Detected :" RESET"ifstmt"CYN" ->"RESET" stmt \n");}
            | whilestmt     {fprintf(yyout, MAG "Detected :" RESET"whilestmt"CYN" ->"RESET" stmt \n");}
            | forstmt       {fprintf(yyout, MAG "Detected :" RESET"forstmt"CYN" ->"RESET" stmt \n");}
            | returnstmt    {fprintf(yyout, MAG "Detected :" RESET"returnstmt"CYN" ->"RESET" stmt \n");}
            | BREAK ";"     {fprintf(yyout, MAG "Detected :" RESET"BREAK ;"CYN""RESET"-> stmt \n");
                                    manage_break(yylineno,is_function_active > 0 ? 0 : loop_flag); }
            | CONTINUE ";"  {fprintf(yyout, MAG "Detected :" RESET"CONTINUE"CYN""RESET"-> while;\n");
                                    manage_continue(yylineno,is_function_active > 0 ? 0 : loop_flag); }
            | block         {fprintf(yyout, MAG "Detected :" RESET"block"CYN" ->"RESET" stmt \n");}
            | funcdef       {fprintf(yyout, MAG "Detected :" RESET"funcdef"CYN" ->"RESET" stmt \n");}
            | ";"           {fprintf(yyout, MAG "Detected :" RESET";"CYN""RESET" -> stmt \n");}
            ;           

expr        : assignexpr    {fprintf(yyout, MAG "Detected :" RESET"assignexpr"CYN" ->"RESET" expr \n");}
            | term          {fprintf(yyout, MAG "Detected :" RESET"term"CYN" ->"RESET" expr \n");}
            | expr "+" expr {fprintf(yyout, MAG "Detected :" RESET"expr + expr"CYN" ->"RESET" expr \n");}
            | expr "*" expr {fprintf(yyout, MAG "Detected :" RESET"expr * expr"CYN" ->"RESET" expr \n");}
            | expr "-" expr {fprintf(yyout, MAG "Detected :" RESET"expr - expr"CYN" ->"RESET" expr \n");}
            | expr "/" expr {fprintf(yyout, MAG "Detected :" RESET"expr / expr"CYN" ->"RESET" expr \n");}
            | expr "%" expr {fprintf(yyout, MAG "Detected :" RESET"expr mod expr"CYN" ->"RESET" expr \n");}
            | expr EQ expr  {fprintf(yyout, MAG "Detected :" RESET"expr == expr"CYN" ->"RESET" expr \n");}
            | expr NEQ expr {fprintf(yyout, MAG "Detected :" RESET"expr != expr"CYN" ->"RESET" expr \n");}
            | expr GT expr  {fprintf(yyout, MAG "Detected :" RESET"expr > expr"CYN" ->"RESET" expr \n");}
            | expr LT expr  {fprintf(yyout, MAG "Detected :" RESET"expr < expr"CYN" ->"RESET" expr \n");}
            | expr GTE expr {fprintf(yyout, MAG "Detected :" RESET"expr >= expr"CYN" ->"RESET" expr \n");}
            | expr LTE expr {fprintf(yyout, MAG "Detected :" RESET"expr <= expr"CYN" ->"RESET" expr \n");}
            | expr AND expr {fprintf(yyout, MAG "Detected :" RESET"expr AND expr"CYN" ->"RESET" expr \n");}
            | expr OR expr  {fprintf(yyout, MAG "Detected :" RESET"expr OR expr"CYN" ->"RESET" expr \n");}
            ;                   

term        : "(" expr ")"          {fprintf(yyout, MAG "Detected :" RESET"( expr )"CYN" ->"RESET" term \n");}
            | "-" expr %prec UMINUS {fprintf(yyout, MAG "Detected :" RESET"UMINUS expr"CYN" ->"RESET" term \n");}
            | NOT expr              {fprintf(yyout, MAG "Detected :" RESET"NOT expr"CYN" ->"RESET" term \n");}
            | "++" lvalue           {fprintf(yyout, MAG "Detected :" RESET"++lvalue"CYN" ->"RESET" term \n"); manage_lvalue_inc(symTable, $2, scope, yylineno);}
            | lvalue "++"           {fprintf(yyout, MAG "Detected :" RESET"lvalue++"CYN" ->"RESET" term \n"); manage_lvalue_inc(symTable, $1, scope, yylineno);}
            | "--" lvalue           {fprintf(yyout, MAG "Detected :" RESET"--lvalue"CYN" ->"RESET" term \n"); manage_lvalue_dec(symTable, $2, scope, yylineno);}
            | lvalue "--"           {fprintf(yyout, MAG "Detected :" RESET"lvalue--"CYN" ->"RESET" term \n"); manage_lvalue_dec(symTable, $1, scope, yylineno);}
            | primary               {fprintf(yyout, MAG "Detected :" RESET"primary"CYN" ->"RESET" term \n");}
            ;   

assignexpr  : lvalue "=" expr       {fprintf(yyout, MAG "Detected :" RESET"lvalue = expr"CYN" ->"RESET" assignexpr \n"); manage_assignment(symTable, $1, scope, yylineno);}
            ;   

primary     : lvalue                {fprintf(yyout, MAG "Detected :" RESET"lvalue"CYN" ->"RESET" primary \n");}
            | call                  {fprintf(yyout, MAG "Detected :" RESET"call"CYN" ->"RESET" primary \n");}
            | objectdef             {fprintf(yyout, MAG "Detected :" RESET"objectdef"CYN" ->"RESET" primary \n");}
            | "(" funcdef ")"       {fprintf(yyout, MAG "Detected :" RESET"( funcdef )"CYN" ->"RESET" primary \n");}
            | const                 {fprintf(yyout, MAG "Detected :" RESET"const"CYN" ->"RESET" primary \n");}
            ;   

lvalue      : IDENT                 {fprintf(yyout, MAG "Detected :" RESET"%s"CYN" ->"RESET" IDENT"CYN" ->"RESET" lvalue \n",yylval.stringVal); manage_id(symTable, yylval.stringVal, IS_GLOBAL, scope, yylineno,in_function_tail); }
            | LOCAL IDENT           {fprintf(yyout, MAG "Detected :" RESET"local \"%s\""CYN" ->"RESET" LOCAL IDENT"CYN" ->"RESET" lvalue \n", yylval.stringVal); $$ = yylval.stringVal; manage_local_id(symTable, yylval.stringVal, scope, yylineno); }
            | "::" IDENT            {fprintf(yyout, MAG "Detected :" RESET"::%s"CYN" ->"RESET" ::IDENT"CYN" ->"RESET" lvalue \n",yylval.stringVal); $$ = yylval.stringVal; manage_global_id(symTable, yylval.stringVal, scope, yylineno);}
            | member                {fprintf(yyout, MAG "Detected :" RESET"member"CYN" ->"RESET" lvalue \n"); $$ = $1;}
            ;   

member      : lvalue "." IDENT      {fprintf(yyout, MAG "Detected :" RESET"lvalue .IDENT"CYN" ->"RESET" member \n");normcall_skip = 1;}
            | lvalue "[" expr "]"   {fprintf(yyout, MAG "Detected :" RESET"lvalue [ expr ]"CYN" ->"RESET" member \n");}
            | call "." IDENT        {fprintf(yyout, MAG "Detected :" RESET"call . IDENT"CYN" ->"RESET" member \n");normcall_skip = 1; $$ = $3;}
            | call "[" expr "]"     {fprintf(yyout, MAG "Detected :" RESET"call [ expr ]"CYN" ->"RESET" member \n");}
            ;

call        : call "(" elist ")"            {fprintf(yyout, MAG "Detected :" RESET"call ( elist )"CYN" ->"RESET" call \n");}
            | lvalue callsuffix             {fprintf(yyout, MAG "Detected :" RESET"lvalue callsuffix"CYN" ->"RESET" call \n"); if(!normcall_skip) {manage_func_call(symTable, $1, scope, yylineno);} normcall_skip=0;}

            | "(" funcdef ")" "(" elist ")" {fprintf(yyout, MAG "Detected :" RESET"( funcdef ) ( elist )"CYN" ->"RESET" call \n");}   
            ;

callsuffix  : normcall   {fprintf(yyout, MAG "Detected :" RESET"normcall"CYN" ->"RESET" callsuffix \n");} 
            | methodcall {fprintf(yyout, MAG "Detected :" RESET"methodcall"CYN" ->"RESET" callsuffix \n");} 
            ;

normcall    : "(" elist ")" {fprintf(yyout, MAG "Detected :" RESET"( elist )"CYN" ->"RESET" normcall \n");}
            ;

methodcall  : ".." IDENT "(" elist ")" {fprintf(yyout, MAG "Detected :" RESET".. IDENT ( elist )"CYN" ->"RESET" methodcall \n");normcall_skip = 1;}
            ;

com_expr_opt : /* empty */             {fprintf(yyout, MAG "Detected :" RESET"com_expr_opt"YEL" (empty) "RESET"\n");}
             | COMMA expr com_expr_opt {fprintf(yyout, MAG "Detected :" RESET"COMMA expr com_expr_opt \n");}
             ;

objectdef   : "[" indexed "]" {fprintf(yyout, MAG "Detected :" RESET"[ indexed ]"CYN" ->"RESET" objectdef \n");}
            | "[" elist   "]" {fprintf(yyout, MAG "Detected :" RESET"[ elist ]"CYN" ->"RESET" objectdef \n");}
            ;

elist       : /* empty */       {fprintf(yyout, MAG "Detected :" RESET"elist"YEL" (empty)"RESET"\n");}
            | expr com_expr_opt {fprintf(yyout, MAG "Detected :" RESET"expr com_expr_opt"CYN" ->"RESET" elist \n");}
            ;
            
indexed     : indexedelem com_indexedelem_opt {fprintf(yyout, MAG "Detected :" RESET"indexedelem com_indexedelem_opt"CYN" ->"RESET" indexed \n");}
            ;

indexedelem     : "{" expr ":" expr "}" {fprintf(yyout, MAG "Detected :" RESET"{ expr : expr }"CYN" ->"RESET" indexedelem \n");}
                ;

com_indexedelem_opt : /* empty */                         {fprintf(yyout, MAG "Detected :" RESET"com_indexedelem_opt "YEL"(empty)"RESET"\n");}
                    | "," indexedelem com_indexedelem_opt {fprintf(yyout, MAG "Detected :" RESET", indexedelem com_indexedelem_opt \n");}
                    ;

block           : "{" {increase_scope(&scope); 
                    if(is_function_block){          
                        in_function_tail = SSL_Push(in_function_tail,1);
                        is_function_block=0;
                    }
                    else
                        in_function_tail = SSL_Push(in_function_tail,0);
                        }     
                                stmtList "}" {
                                                                symbol_table_hide(symTable,scope);
                                                                decrease_scope(&scope);
                                                                in_function_tail = SSL_Pop(in_function_tail);
                                                                fprintf(yyout, MAG "Detected :" RESET"{ stmtList }"CYN" ->"RESET" block \n");
                                                             }
                ;

stmtList        : /* empty */   {fprintf(yyout, MAG "Detected :" RESET"stmtList"YEL" (empty)"RESET":\n");}
                | stmt stmtList {fprintf(yyout, MAG "Detected :" RESET"stmt stmtList"CYN" ->"RESET" stmtList \n");}
                ;
                                                                                
funcdef         : funcprefix                            
                                 "("                    {   increase_scope(&scope); 
                                                            unsigned int *p_x = (unsigned int*)malloc(sizeof(unsigned int));
                                                            *p_x = currScopeOffset(); 
                                                            if(!scope_offset_stack) scope_offset_stack = new_stack(); 
                                                            push(scope_offset_stack,p_x); 
                                                            enterScopeSpace(); 
                                                            resetFormalArgsOffset();
                                                        } 
                                    idlist ")"          {decrease_scope(&scope); enterScopeSpace(); resetFunctionLocalsOffset();
                                                        return_flag++;
                                                        is_function_block=1;
                                                        is_function_active++;
                                                        } 
                                               block    {
                                                            fprintf(yyout, MAG "Detected :" RESET"FUNCTION id_opt ( idlist ) block"CYN" ->"RESET" funcdef \n"); 
                                                            formal_flag = 0; //reset flag
                                                            return_flag--;
                                                            is_function_active--;

                                                            $1->totalLocals = currScopeOffset();
                                                            exitScopeSpace();

                                                            restoreCurrScopeOffset(*(unsigned int *)pop(scope_offset_stack));
                                                         }
                                                                                                             
                                                                                            
                ;

funcprefix : FUNCTION id_opt {
                            if(!func_line_stack){func_line_stack=new_stack();}  
                            unsigned int* tmp_line = malloc(sizeof(unsigned int)); 
                            *tmp_line = yylineno;
                            push(func_line_stack,tmp_line);
                            //Kanoume check edw gia na settaroume to flag stin periptwsi pou i sunartisi uparxei (i einai lib)
                            check_if_declared(symTable,$2,scope);
                            //Kanoume to manage edw giati olokliros o kanonas anagetai otan kleisei to block
                            //alla emeis theloume na mpenei sto symbol table molis tin doume
                            $$ = manage_funcdef(symTable, $2, scope,*(unsigned int *)pop(func_line_stack)); 
                            }
                            ;

id_opt  : /* empty */ { //giving a name to anonymous functions
                        fprintf(yyout, MAG "Detected :" RESET"id_opt "YEL" (empty) "RESET"\n"); 
                        char buffer[255]; 
                        sprintf(buffer, "_anonymous_f%d", anonym_cnt++); 
                        $$ = strdup(buffer); 
                    }
        | IDENT       {fprintf(yyout, MAG "Detected :" RESET"%s"CYN" -> "RESET"IDENT \n",yylval.stringVal);}
        ;

const           : INTCONST  {fprintf(yyout, MAG "Detected :" RESET"%d"CYN"-> "RESET"INTCONST"CYN"-> "RESET"const \n",yylval.intVal);}
                | REALCONST {fprintf(yyout, MAG "Detected :" RESET"%lf"CYN"-> "RESET"REALCONST"CYN"-> "RESET"const \n",yylval.realVal);}
                | STRING    {fprintf(yyout, MAG "Detected :" RESET"%s"CYN"-> "RESET"STRING"CYN"-> "RESET"const \n",yylval.stringVal);}
                | TRUE      {fprintf(yyout, MAG "Detected :" RESET"TRUE"CYN"-> "RESET"const \n");}
                | FALSE     {fprintf(yyout, MAG "Detected :" RESET"FALSE"CYN"-> "RESET"const \n");}
                | NIL       {fprintf(yyout, MAG "Detected :" RESET"NIL"CYN"-> "RESET"const \n");}
                ;

idlist          : /* empty */          {fprintf(yyout, MAG "Detected :" RESET"idlist"YEL" (empty)"RESET"\n");}
                | IDENT com_id_opt     {fprintf(yyout, MAG "Detected :" RESET"IDENT com_id_opt \n"); manage_formal_id(symTable, $1, scope, yylineno);}
                ;

com_id_opt      : /* empty */          {fprintf(yyout, MAG "Detected :" RESET"com_id_opt"YEL" (empty)"RESET"\n");}
                | "," IDENT com_id_opt {fprintf(yyout, MAG "Detected :" RESET", IDENT com_id_opt \n"); manage_formal_id(symTable, $2, scope, yylineno);}
                ;

ifstmt          : IF "(" expr ")" stmt %prec LP_ELSE {fprintf(yyout, MAG "Detected :" RESET"IF ( expr ) stmt"CYN"-> "RESET"ifstmt  \n");}
                | IF "(" expr ")" stmt ELSE stmt     {fprintf(yyout, MAG "Detected :" RESET"IF ( expr ) stmt ELSE stmt"CYN"-> "RESET"ifstmt \n");}
                ;

whilestmt       : WHILE "(" expr ")" {loop_flag++;} stmt {loop_flag--;} {fprintf(yyout, MAG "Detected :" RESET"WHILE ( expr ) stmt"CYN"-> "RESET"whilestmt \n");}
                ;

forstmt         : FOR "(" elist ";" expr ";" elist ")" {loop_flag++;} stmt {loop_flag--;} {fprintf(yyout, MAG "Detected :" RESET"FOR ( elist ; expr ; elist ) stmt"CYN"-> "RESET"forstmt \n");}
                ;

returnstmt      : RETURN expr_opt ";" {fprintf(yyout, MAG "Detected :" RESET"RETURN expr_opt ;"CYN"-> "RESET"returnstmt \n");
                                        manage_return(yylineno, return_flag);}
                ;

expr_opt        : /* empty */ {fprintf(yyout, MAG "Detected :" RESET"expr_opt "YEL" (empty)"RESET"\n");}
                | expr        {fprintf(yyout, MAG "Detected :" RESET"expr \n");}
                ;

%%