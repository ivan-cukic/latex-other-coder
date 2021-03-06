Other Coder
===========

![Demo](https://github.com/ivan-cukic/latex-other-coder/raw/master/images/othercoder.png)

Yet another Verbatim environment?
---------------------------------

Other Coder is a LuaLaTeX package
for code listings that do not need to have syntax highlighting.

Namely,
in shorter code examples,
syntax highlighting does not bring that much useful information.
It is more important to be able to highlight
specific parts of the code
so that the reader can focus on them.

The LaTeX packages I've seen so far
do not provide an intuitive way to do this,
and that is the reason
behind the creation of this package.


Syntax
------

The main idea
is to allow *visual* annotations in the code
and to convert them to a nice representation for printing.
I don't like having to say "highlight lines from 8-12".
It is error prone,
and not easily maintained.

Instead,
the highlighting markup is in the source code itself,
but it is not overly intrusive.
See the example file.


Project status
--------------

The implementation is a bit dirty, but it works.
I do not plan to introduce any breaking changes regarding
the markup syntax.


Why MoonScript?
---------------

I'm not particularly astonished by Lua
so I decided to try a language that compiles to it.
The first stable language that compiles to Lua I encountered was MoonScript,
so I went with it.

It is nothing special, but it is nicer than Lua.


Will it support something beside LuaLaTex
-----------------------------------------

I do not have such plans,
but patches are welcome.


Naming
------

The project name is a bit of a tribute to Neil Gaiman.


License
-------

The code is published under the
[GNU Lesser General Public License version 3](https://www.gnu.org/licenses/lgpl-3.0.en.html) or later.

