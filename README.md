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

MIT License
