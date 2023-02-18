enum type{
    STRING,
    INTCONST,
    REALCONST,
    IDENT,
    OPERATOR,
    KEYWORD,
    PUNCTUATION,
    COMMENT
};

enum operator{
    ASSIGN,
    PLUS,
    MINUS,
    MUL,
    SLASH,
    MOD,
    EQ,
    NEQ,
    INC,
    DEC,
    GT,
    LT,
    GTE,
    LTE
}

enum keyword{
    IF,
    ELSE,
    WHILE,
    FOR,
    FUNCTION,
    RETURN,
    BREAK,
    CONTINUE,
    AND,
    NOT,
    OR,
    LOCAL,
    TRUE,
    FALSE,
    NIL
}

struct alpha_token_t {
  unsigned int     numline;
  unsigned int     numToken;
  char          *content;
  enum          type;
  struct alpha_token_t *alpha_yylex;
};

typedef struct alpha_token_t alpha_token_t;