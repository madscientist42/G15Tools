%{
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <libg15.h>
#include <libg15render.h>
#include <g15daemon_client.h>

#include "g15composer.h"

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

struct strList *listptr;
struct strItem *itemptr;
g15canvas *canvas;
int g15screen_fd;
extern FILE *yyin;
char *fifo_filename = NULL;
int yydebug = 0;
int mkey_state = 0;
int leaving = 0;
%}

%union
{
	int number;
	char *string;
	struct strList *strList;
}

%token <number> T_NUMBER
%token <string> T_STRING
%token T_NEWLINE
%token T_PIXELSET
%token <number> T_PIXELFILL
%token T_PIXELOVERLAY
%token T_PIXELBOX
%token T_PIXELCLEAR
%token T_DRAWLINE
%token T_DRAWCIRCLE
%token T_DRAWRBOX
%token T_DRAWBAR
%token T_MODECACHE
%token T_MODEREV
%token T_MODEXOR
%token T_MODEPRI
%token T_FONTLOAD
%token T_FONTPRINT
%token T_TEXTSMALL
%token T_TEXTMED
%token T_TEXTLARGE
%token T_TEXTOVERLAY
%token T_KEYL
%token T_KEYM
%token T_LCDBL
%token T_LCDCON
%token T_SCREENNEW
%token T_SCREENCLOSE

%type <string> nt_string
%type <strList> nt_strings

%start nt_program

%%

nt_program:
	nt_commands nt_quit_command
	;

nt_quit_command:
	T_SCREENCLOSE T_NEWLINE
	{
		leaving = 1;
		return (0);
	}
	;

nt_commands: /* empty */
	| nt_commands nt_command
	{
		updateScreen (0);
	}
	;

nt_command:
	nt_pixel_command 
	| nt_draw_command 
	| nt_mode_command 
	| nt_font_command 
	| nt_text_command
	{
		itemptr = listptr->first_string;
		while (itemptr != 0)
		  {
		  	free (itemptr->string);
			struct strItem *tmpItem = itemptr;
			itemptr = itemptr->next_string;
			free (tmpItem);
		  }
		free (listptr);
	}
	| nt_key_command 
	| nt_lcd_command 
	| nt_screen_command
	;

nt_string:
	T_STRING 
	{
		$$ = $1;
	}
	;

nt_strings: /* empty */
	{
		$$ = new_strList ();
	}

	| 
	
	nt_strings nt_string
	{
		add_string ($1, $2);
		$$ = $1;
	}
	;

nt_pixel_command:
	T_PIXELSET T_NUMBER T_NUMBER T_NUMBER T_NEWLINE
	{
		g15r_setPixel (canvas, $2, $3, $4);
	}

	|

	T_PIXELFILL T_NUMBER T_NUMBER T_NUMBER T_NUMBER T_NUMBER T_NEWLINE
	{
		int fill = $1;
		int color = G15_COLOR_WHITE;

		if (fill == 1)
		  color = $5;

		g15r_pixelReverseFill (canvas, $2, $3, $4, $5, fill, color);
	}

	|

	T_PIXELOVERLAY T_NUMBER T_NUMBER T_NUMBER T_NUMBER nt_string T_NEWLINE
	{
		short output_line[G15_BUFFER_LEN];
		int len = strlen ($6);
		int exp = $4 * $5;

		if ((len != exp) || (len > G15_BUFFER_LEN))
		  {
		  	fprintf (stderr, "Error: Expected %d pixels but received %d.\n", exp, len);
			return (1);
		  }

		int i = 0;

		for (i = 0; i < len; ++i)
		  {
	  	    	output_line[i] = 0;
		    	if ($6[i] == '1')
	      	          output_line[i] = 1;
	      	  }
	  	g15r_pixelOverlay (canvas, $2, $3, $4, $5, output_line);
		free ($6);
	}

	|

	T_PIXELBOX T_NUMBER T_NUMBER T_NUMBER T_NUMBER T_NUMBER T_NUMBER T_NUMBER T_NEWLINE
	{
		g15r_pixelBox (canvas, $2, $3, $4, $5, $6, $7, $8);
	}

	|

	T_PIXELCLEAR T_NUMBER T_NEWLINE
	{
		g15r_clearScreen (canvas, $2);
	}
	;

nt_draw_command:
	T_DRAWLINE T_NUMBER T_NUMBER T_NUMBER T_NUMBER T_NUMBER T_NEWLINE
	{
		g15r_drawLine (canvas, $2, $3, $4, $5, $6);
	}

	|

	T_DRAWCIRCLE T_NUMBER T_NUMBER T_NUMBER T_NUMBER T_NUMBER T_NEWLINE
	{
		g15r_drawCircle (canvas, $2, $3, $4, $5, $6);
	}

	|

	T_DRAWRBOX T_NUMBER T_NUMBER T_NUMBER T_NUMBER T_NUMBER T_NUMBER T_NEWLINE
	{
		g15r_drawRoundBox (canvas, $2, $3, $4, $5, $6, $7);
	}

	|

	T_DRAWBAR T_NUMBER T_NUMBER T_NUMBER T_NUMBER T_NUMBER T_NUMBER T_NUMBER T_NUMBER T_NEWLINE
	{
		g15r_drawBar (canvas, $2, $3, $4, $5, $6, $7, $8, $9);
	}
	;

nt_mode_command:
	T_MODECACHE T_NUMBER T_NEWLINE
	{
		int was_cached = canvas->mode_cache;
		canvas->mode_cache = $2;
		if (was_cached)
		  updateScreen (1);
	}

	|

	T_MODEREV T_NUMBER T_NEWLINE
	{
		canvas->mode_reverse = $2;
	}

	|

	T_MODEXOR T_NUMBER T_NEWLINE
	{
		canvas->mode_xor = $2;
	}

	|

	T_MODEPRI T_NUMBER T_NEWLINE
	{
		int fore = ($2 == 0) ? 1 : 0;
		int rear = ($2 == 1) ? 1 : 0;
		int revert = ($2 == 2) ? 1 : 0;
		char msgbuf[1];

		msgbuf[0] = 'v';	/* Is the display visible? */
		send (g15screen_fd, msgbuf, 1, MSG_OOB);
		recv (g15screen_fd, msgbuf, 1, 0);
		int at_front = (msgbuf[0] != 0) ? 1 : 0;
		msgbuf[0] = 'u';	/* Did the user make the display visible? */
		send (g15screen_fd, msgbuf, 1, MSG_OOB);
		recv (g15screen_fd, msgbuf, 1, 0);
		int user_to_front = (msgbuf[0] != 0) ? 1 : 0;
		msgbuf[0] = 'p';	/* We now want to change the priority */
		int sendCmd = 0;
		if (at_front == 1)
		  {
		    if (rear == 1)		/* we want to go to the back */
		      {
			sendCmd = 1;
		      }
		    else if ((user_to_front == 0) && (revert == 1))	/* we want to go to the back if forced to the front */
		      {
			sendCmd = 1;
		      }
		  }
		else
		  {
		    if (fore == 1)		/* we want to go to the front */
		      {
			sendCmd = 1;
		      }
		    else if ((user_to_front == 0) && (revert == 1))	/* we want to take back the foreground if forced to the back */
		      {
			sendCmd = 1;
		      }
		  }
		if (sendCmd == 1)
		  send (g15screen_fd, msgbuf, 1, MSG_OOB);
	}
	;

nt_font_command:
	T_FONTLOAD T_NUMBER T_NUMBER nt_string T_NEWLINE
	{
		#ifdef TTF_SUPPORT
		g15r_ttfLoad (canvas, $4, $3, $2);
		#endif
		free ($4);
	}

	|

	T_FONTPRINT T_NUMBER T_NUMBER T_NUMBER T_NUMBER T_NUMBER T_NUMBER nt_string T_NEWLINE
	{
		#ifdef TTF_SUPPORT
		g15r_ttfPrint (canvas, $4, $5, $3, $2, $6, $7, $8);
		#endif
		free ($8);
	}
	;

nt_text_command:
	T_TEXTSMALL nt_strings T_NEWLINE
	{
		listptr = $2;
		itemptr = listptr->first_string;

		int row = 0;
		for (row = 0; itemptr != 0; ++row)
		  {
			g15r_renderString (canvas, itemptr->string, row, G15_TEXT_SMALL, 0, 0);
			itemptr = itemptr->next_string;
		  }
	}

	|

	T_TEXTMED nt_strings T_NEWLINE
	{
		listptr = $2;
		itemptr = listptr->first_string;

		int row = 0;
		for (row = 0; itemptr != 0; ++row)
		  {
			g15r_renderString (canvas, itemptr->string, row, G15_TEXT_MED, 0, 0);
			itemptr = itemptr->next_string;
		  }
	}

	|

	T_TEXTLARGE nt_strings T_NEWLINE
	{
		listptr = $2;
		itemptr = listptr->first_string;

		int row = 0;
		for (row = 0; itemptr != 0; ++row)
		  {
			g15r_renderString (canvas, itemptr->string, row, G15_TEXT_LARGE, 0, 0);
			itemptr = itemptr->next_string;
		  }
	}

	|

	T_TEXTOVERLAY T_NUMBER T_NUMBER T_NUMBER T_NUMBER nt_strings T_NEWLINE
	{
		listptr = $6;
		itemptr = listptr->first_string;

		int row = 0;
		for (row = 0; itemptr != 0; ++row)
		  {
			if ($5)
			  {
			  	unsigned int dispcol = 0;
				unsigned int len = strlen (itemptr->string);
				
				if ($4 == 0)
				  dispcol = (80 - ((len * 4) / 2));
				if ($4 == 1)
				  dispcol = (80 - ((len * 5) / 2));
				if ($4 == 2)
				  dispcol = (80 - ((len * 8) / 2));
				if (dispcol < 0)
				  dispcol = 0;
				g15r_renderString (canvas, itemptr->string, row, $4, dispcol, $3);
			  }
			else
			  g15r_renderString (canvas, itemptr->string, row, $4, $2, $3);
			itemptr = itemptr->next_string;
		  }
	}
	;

nt_key_command:
	T_KEYL T_NUMBER T_NEWLINE 
	{
	}

	|

	T_KEYM T_NUMBER T_NUMBER T_NEWLINE
	{
		int sendCmd = 1;
		int LEDon = $3;
		mkey_state |= G15DAEMON_MKEYLEDS;
		switch ($2)
		  {
		  case 0:
		    {
		      if (LEDon != 0)
			mkey_state |= G15_LED_M1 | G15_LED_M2 | G15_LED_M3;
		      else
			mkey_state &= ~G15_LED_M1 & ~G15_LED_M2 & ~G15_LED_M3;
		      break;
		    }
		  case 1:
		    {
		      if (LEDon != 0)
			mkey_state |= G15_LED_M1;
		      else
			mkey_state &= ~G15_LED_M1;
		      break;
		    }
		  case 2:
		    {
		      if (LEDon != 0)
			mkey_state |= G15_LED_M2;
		      else
			mkey_state &= ~G15_LED_M2;
		      break;
		    }
		  case 3:
		    {
		      if (LEDon != 0)
			mkey_state |= G15_LED_M3;
		      else
			mkey_state &= ~G15_LED_M3;
		      break;
		    }
		  default:
		    {
		      sendCmd = 0;
		      break;
		    }
		  }
		if (sendCmd == 1)
		  send (g15screen_fd, &mkey_state, 1, MSG_OOB);
	}
	;

nt_lcd_command:
	T_LCDBL T_NUMBER T_NEWLINE
	{
		char msgbuf = G15DAEMON_BACKLIGHT | $2;
		send (g15screen_fd, &msgbuf, 1, MSG_OOB);
	}

	|

	T_LCDCON T_NUMBER T_NEWLINE
	{
		char msgbuf = G15DAEMON_CONTRAST | $2;
		send (g15screen_fd, &msgbuf, 1, MSG_OOB);
	}
	;

nt_screen_command:
	T_SCREENNEW nt_string T_NEWLINE
	{
	}
	;

%%

int yywrap() 
{
	fclose (yyin);
	if ((yyin = fopen (fifo_filename,"r")) == 0)
	  {
	  	perror (fifo_filename);
		return (1);
	  }
	if (!canvas->mode_cache)
	  g15r_clearScreen (canvas, G15_COLOR_WHITE);
	return (0);
}

int yyerror(char *err) 
{
	fprintf (stderr, "Error: %s\n",err);
	return (0);
}

int main(int argc, char *argv[])
{
	int background = 0;

	int i = 1;
	for (i = 1; (i < argc && fifo_filename == NULL); ++i)
	  {
	    if (!strcmp (argv[i],"-h") || !strcmp (argv[i],"--help"))
	      {
//	        printUsage ();
	        return 0;
	      }
	    else if (!strcmp (argv[i],"-b"))
	      {
	        background = 1;
	      }
	    else
	      {
	        fifo_filename = argv[i];
	      }
	  }
	
	if (fifo_filename != NULL)
	  {
	  	canvas = (g15canvas *) malloc (sizeof (g15canvas));
		if ((yyin = fopen (fifo_filename,"r")) == 0)
		  {
		  	perror( fifo_filename);
			exit (1);
		  }
		if ((g15screen_fd = new_g15_screen (G15_G15RBUF)) < 0)
		  {
		  	fprintf (stderr, "Sorry, can't connect to g15daemon\n");
			exit (1);
		  }
		g15r_initCanvas (canvas);
		int result = 0;
		while (leaving == 0)
		  {
			result = yyparse();
		  }
		g15_close_screen (g15screen_fd);
		free (canvas);
		return result;
	  }
}

struct strList * 
new_strList ()
{
	struct strList *new;
	new = (struct strList *) malloc (sizeof (struct strList));
	new->first_string = 0;
	new->last_string = 0;

	return new;
}

void 
add_string (struct strList *list, char *string)
{
	struct strItem *new;
	new = (struct strItem *) malloc (sizeof (struct strItem));
	new->string = strdup(string);
	new->next_string = NULL;

	if (list->first_string == 0)
	  list->first_string = new;
	else
	  list->last_string->next_string = new;
	list->last_string = new;
	free (string);
}

void
updateScreen (int force)
{
	if (force || !canvas->mode_cache)
	  g15_send (g15screen_fd, (char *) canvas->buffer, 1048);
}
