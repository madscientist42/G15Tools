#    This file is part of g15tools.
#
#    g15tools is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    g15tools is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with g15tools; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

all:
	flex -o g15composer.lex.c g15composer.l
	bison -d g15composer.y
	gcc g15composer.tab.c g15composer.lex.c -lfreetype -lg15render -lg15daemon_client -o g15composer -g -I/usr/include/freetype2

clean:
	rm -f g15composer
	rm -f *.tab.*
	rm -f *.lex.c
