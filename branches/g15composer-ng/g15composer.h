struct strList;
struct strItem;

struct strList
{
	struct strItem *first_string;
	struct strItem *last_string;
};

struct strItem
{
	char *string;
	struct strItem *next_string;
};

struct parserData
{
	int g15screen_fd;
	g15canvas *canvas;
	struct strList *listptr;
	struct strItem *itemptr;
	char *fifo_filename;
	int mkey_state;
	int leaving;
	void *scanner;
};

typedef struct strList *List;
typedef struct strItem *String;

struct strList * new_strList ();
void add_string (struct strList *strList, char *string);
void updateScreen (g15canvas *canvas, int g15screen_fd, int force);
