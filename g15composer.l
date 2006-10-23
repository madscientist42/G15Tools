%{
#include <stdio.h>
#include <string.h>

#include "g15composer.tab.h"

//extern YYSTYPE yylval;
%}

%%

^PS			return T_PIXELSET;
^P[RF]			yylval.number=(yytext[1] == 'F' ? 1 : 0); return T_PIXELFILL;
^PO			return T_PIXELOVERLAY;
^PB			return T_PIXELBOX;
^PC			return T_PIXELCLEAR;
^DL			return T_DRAWLINE;
^DC			return T_DRAWCIRCLE;
^DR			return T_DRAWRBOX;
^DB			return T_DRAWBAR;
^MC			return T_MODECACHE;
^MR			return T_MODEREV;
^MX			return T_MODEXOR;
^MP			return T_MODEPRI;
^FL			return T_FONTLOAD;
^FP			return T_FONTPRINT;
^TS			return T_TEXTSMALL;
^TM			return T_TEXTMED;
^TL			return T_TEXTLARGE;
^TO			return T_TEXTOVERLAY;
^KL			return T_KEYL;
^KM			return T_KEYM;
^LB			return T_LCDBL;
^LC			return T_LCDCON;
^SN			return T_SCREENNEW;
^SC			return T_SCREENCLOSE;
[0-9]+                  yylval.number=atoi(yytext); return T_NUMBER;
\"[^\"\r\n]*\"		yylval.string=strdup(yytext+1); yylval.string[yyleng-2] = NULL; return T_STRING;
\n                      return T_NEWLINE;
[ \t]+                  /* ignore whitespace */;

%%
