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

typedef struct strList *List;
typedef struct strItem *String;

struct strList * new_strList ();
void add_string (struct strList *strList, char *string);
void updateScreen (int force);
