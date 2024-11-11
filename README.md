## Project title

upkg

## Description

upkg is a Perl module to extract information from Unreal Tournament (UT99) packages. It was derived from [utdep.pl](https://github.com/cterveen/utdep.pl) to make it easier to extract information by perl scripts. Methods for the extraction of some data types have been included.

The package can be considered alfa. It has been used in various projects but only partial support for exporting data is included. Several bugs still exist. POD documentation is available. The module is not on CPAN.

No further development is intended.

## Installation

Save upkg.pm in any Perl module directory.

## Use

    use upkg;
    
    my $pkg = upkg->new();
       $pkg->load("CTF-Face.unr");
    
    print join("\n", $pkg->getDependencies());

See also the POD documentation.

## Credits

Package written by Christiaan ter Veen <https://www.rork.nl/>

Thanks to Just**Me at the [Beyond Unreal](https://www.beyondunreal.com/) Forums for getting me on the way and providing an example script.

Thanks Antonio Cordero for the Unreal Tournament Package File Format documentation and the Delphi libraries.

Technical details

- Unreal Tournament Package File Format: <https://archive.org/details/ut-package-file-format>

## Copyright

Copyright (c) 2008-2013 Christiaan ter Veen

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software with the restrictions of the Unreal(r) Engine End User License Agreement but no restrictions otherwise.

The Unreal(r) Engine End User License Agreement states the following: You may Distribute an integration of a programming language other than C++ for the Licensed Technology, but if you do, the integration must be Distributed free of charge to all Engine Licensees, must be available in source code form (including, but not limited to, any compiler, linker, toolchain, and runtime), and must permit Distribution free of charge, on all platforms, in any Product.

Otherwise, the software can be dealt with without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, and/or sublicense copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
