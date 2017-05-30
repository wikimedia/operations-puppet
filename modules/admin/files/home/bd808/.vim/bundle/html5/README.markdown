# html5.vim

HTML5 omnicomplete funtion and syntax for Vim.
Based on the default htmlcomplete.vim.

## Feature

- Support all new elements and attribute.
- Support [microdata][microdata].
- Support [RDFa][RDFa].
- Support [WAI-ARIA][aria].

## Install

Goto [get][html5.vim] vimball file. Open it with vim and execute :so%
or 

    git clone git://github.com/othree/html5.vim.git
    cd html5.vim
    make install

## Configure

Disable event-handler attributes support:

    let g:html5_event_handler_attributes_complete = 0

Disable RDFa attributes support:

    let g:html5_rdfa_attributes_complete = 0

Disable microdata attributes support:

    let g:html5_microdata_attributes_complete = 0

Disable WAI-ARIA attribute support:

    let g:html5_aria_attributes_complete = 0

## Change Log

### Version 0.26

- Support multi-value attributes (Most of them are WAI-ARIA attributes)
- Some old complete function bug fix

### Version 0.25

- WAI-ARIA support bug fix
- WAI-ARIA complete supports all doctypes now

## License

Copyright (c) 2010 Wei-Ko Kao

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

## References
 
1. [HTML5 Spec][1]
2. [HTML5 Markup][2]
3. [Custom Data Attributes][3]
4. [microdata][4]
5. [RDFa 1.0 Rec][5]
6. [RDFa 1.1 Core WD][6]
7. [WAI-ARIA][7]
8. [IANA Language Sub Tags][8]
9. [IANA Charset][9]

[html5.vim]:http://www.vim.org/scripts/script.php?script_id=3236

[microdata]:http://dev.w3.org/html5/md/
[RDFa]:http://www.w3.org/TR/rdfa-syntax/
[aria]:http://www.w3.org/TR/wai-aria/

[1]:http://dev.w3.org/html5/spec/
[2]:http://dev.w3.org/html5/markup/
[3]:http://dev.w3.org/html5/spec/Overview.html#custom-data-attribute
[4]:http://dev.w3.org/html5/md/
[5]:http://www.w3.org/TR/rdfa-syntax/#a_xhtmlrdfa_dtd
[6]:http://www.w3.org/TR/rdfa-core/
[7]:http://www.w3.org/TR/wai-aria/
[8]:http://www.iana.org/assignments/language-subtag-registry
[9]:http://www.iana.org/assignments/character-sets 
