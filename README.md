## Project title

upkg

## Description

upkg is a Perl module to extract information from Unreal Tournament (UT99) packages. It was derived from [utdep.pl](https://github.com/cterveen/utdep.pl) to make it easier to extract information by perl scripts. Methods for the extraction of some data types have been included.

The package can be considered beta. Methods for extracting and parsing more data types can be added. POD documentation is available. The module is not on CPAN.

The module has been used in various projects. No further development is intended.

## Installation

Save the file in any Perl module directory.

## Use

    use upkg;
    
    my $pkg = upkg->new();
       $pkg->load("CTF-Face.unr");
    
    print join("\n", $pkg->getDependencies());

See also the POD documentation.

## Credits

Thanks to Just**Me at the [Beyond Unreal](https://www.beyondunreal.com/) Forums for getting me on the way and providing an example script.  

Technical details

- Unreal Tournament Package File Format: <https://archive.org/details/ut-package-file-format>

## Copyright

To be decided, but consider it free to use, modify and distribute.
