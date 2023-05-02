#include "quad.h"

quad* quads = (quad *) 0;
unsigned int total = 0;
unsigned int currQuad = 0;

void expand(){

    assert(total == currQuad);
    quad *p = (quad *)malloc(NEW_SIZE);
    if(quads){
        memcpy(p, quads, CURR_SIZE);
        free(quads);
    }

    quads = p;
    total += EXPAND_SIZE;
}   


void emit(enum iopcode op, expr *arg1, expr *arg2, expr *result, unsigned label, unsigned line){
    if(currQuad == total)
        expand();

    quad *p = quads + currQuad++;
    p->op = op;
    p->arg1 = arg1;
    p->arg2 = arg2;
    p->result = result;
    p->label = label;
    p->line = line;
}

unsigned int nextQuadLabel(){
        return currQuad;
}

void patchLabel(unsigned quadNo, unsigned label){
    assert(quadNo < currQuad);
    quads[quadNo].label = label;
}

void printQuads(){
    int i;
    for(i = 0; i < currQuad; i++){
        printf("%d: OP: "BLU"%s"RESET"\t", i, iopcode_tostring(quads[i].op));
        if(quads[i].result != NULL){
            if(quads[i].result->type == var_e)
                printf(" RESULT: "YEL"%s"RESET"\t", quads[i].result->sym->name);
            else if(quads[i].result->type == constnum_e)
                printf(" RESULT: "YEL"%.2f"RESET"\t", quads[i].result->numConst);
            else if(quads[i].result->type == constbool_e)
                printf(" RESULT: "YEL"%d"RESET"\t", quads[i].result->boolConst);
            else if(quads[i].result->type == conststring_e)
                printf(" RESULT: "YEL"%s"RESET"\t", quads[i].result->strConst);
            else if(quads[i].result->type == nil_e)
                printf(" RESULT: "YEL"nil"RESET"\t");
        }
        else
            printf(" RESULT: "RED"NULL"RESET"\t");        
        if(quads[i].arg1 != NULL){
            if(quads[i].arg1->type == var_e)
                printf(" ARG1: "YEL"%s"RESET"\t", quads[i].arg1->sym->name);
            else if(quads[i].arg1->type == constnum_e)
                printf(" ARG1: "YEL"%.2f"RESET"\t", quads[i].arg1->numConst);
            else if(quads[i].arg1->type == constbool_e)
                printf(" ARG1: "YEL"%d"RESET"\t", quads[i].arg1->boolConst);
            else if(quads[i].arg1->type == conststring_e)
                printf(" ARG1: "YEL"%s"RESET"\t", quads[i].arg1->strConst);
            else if(quads[i].arg1->type == nil_e)
                printf(" ARG1: "YEL"nil"RESET"\t");
        }
        else
            printf(" ARG1: "RED"NULL"RESET"\t");
        if(quads[i].arg2 != NULL){
            if(quads[i].arg2->type == var_e)
                printf(" ARG2: "YEL"%s"RESET"\t", quads[i].arg2->sym->name);
            else if(quads[i].arg2->type == constnum_e)
                printf(" ARG2: "YEL"%.2f"RESET"\t", quads[i].arg2->numConst);
            else if(quads[i].arg2->type == constbool_e)
                printf(" ARG2: "YEL"%d"RESET"\t", quads[i].arg2->boolConst);
            else if(quads[i].arg2->type == conststring_e)
                printf(" ARG2: "YEL"%s"RESET"\t", quads[i].arg2->strConst);
            else if(quads[i].arg2->type == nil_e)
                printf(" ARG2: "YEL"nil"RESET"\t");
        }
        else
            printf(" ARG2: "RED"NULL"RESET"\t");
        if (quads[i].label == -1)
            printf(" LABEL: UNSET\t");
        else
            printf(" LABEL: %d  \t", quads[i].label);
        printf("LINE: "GRN"%d"RESET"\n", quads[i].line);
    }
}

const char* iopcode_tostring(enum iopcode op){
    switch (op)
    {
        case assign: return "assign";
        case add: return "add";
        case sub: return "sub";
        case mul: return "mul";
        case i_div: return "div";
        case mod: return "mod";
        case uminus: return "uminus";
        case and: return "and";
        case or: return "or";
        case not: return "not";
        case if_eq: return "eq";
        case if_noteq: return "neq";
        case if_lesseq: return "leq";
        case if_greatereq: return "geq";
        case if_less: return "lt";
        case if_greater: return "gt";
        case call: return "call";
        case param: return "param";
        case ret: return "ret";
        case getretval: return "getretval";
        case funcstart: return "funcstart";
        case funcend: return "funcend";
        case tablecreate: return "tablecreate";
        case tablegetelem: return "tablegetelem";
        case tablesetelem: return "tablesetelem";
        case jump: return "jump";
        default:
            return "unknown";
    }
}
