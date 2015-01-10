upkg
====

NAME

upkg - extract information from Unreal Tournament packages

SYNOPSIS

use upkg;
  
my $pkg = upkg->new();
   $pkg->load("CTF-Face.unr");
     
print join("\n", $pkg->getDependencies());
  
DESCRIPTION

This module is used to extract information from Unreal Tournament '99 packages.
Extraction of basic information like the head, name, import and export table is
implemented as well as extraction of some specific objects (see below);
  
METHODS

General methods

load() - load a map, this reads the header, name table, import table and export
table and returns an object. The tables can be retrieved from
%{$pkg->{'headers'}}, @{$pkg->{'names'}}, @{$pkg->{'imports'}} and
@{$pkg->{'exports'}}.
  
debuglog() - Returns the debuglog for the current session
  
getName($nameid) - Returns the name of $nameid from the names table

getPackage($classname) - Returns a string with the package a class belongs to
or "Unknown" on fail.

getObject($objectid) - Returns a hash with the object properties.

getDependencies() - Returns an array with the dependencies of a package. If the
file type could be determined the correct extension is used, otherwise .uxx is
used.

Brushes

Brushes contain the geometry of Unreal Tournament maps. Actually the brush
itself contains the brush properties only. The property 'Brush' is an object
reference to a Model object. The model in its turnholds an object reference to a
Polys object which contains the actual geometry of the brush.

getBrush($objectid) - Returns the brush object including raw information of the 
Polys object.

getModel($objectid) - Returns the Polys object reference. I do not exactly know
how to retrieve this information, a workaround is used which may fail!

getPolys($objectid) - Returns an array with each of the polys coordinates:
  ([x1,y1,z1],[x2,y2,z2],...)

Textures
  
getTexture($objectid) - Returns a hash with the texture properties
  
getPallette($objectid) - Returns a hash with the pallette
  
Meshes
  
getMesh($objectid) - Returns a hash with the mesh properties
  
KNOWN ISSUES

DEVELOPMENT - Development of this package was goal driven. Therefore methods
usually don't return full information but only the required information. More
and different features may be added in the future.

MODELS - The method to extract the Polys object from a model uses a bypass and
might not work all the time. The description of a model does not fit the data
in a map. It currently jumps to the position the Polys object is expected, if
any data is added before this it will likely fail (so always check if a Polys
object is returned.
  
OTHER GAMES - Although the same game engine and package file format is used
for multiple games upkg has not been made for or tested on packages other than
for Unreal Tournament '99 (package version 68).
  
COPYRIGHTS & DISCLAIMER

You have the right to copy this script, you may also redistribute, adapt and
rewrite it if you want. I can't be held responsible for any damage of this
script did to your system, especially not when they are redistributed or
addapted by other persons. Use the script at your own risk.
  
ACKNOWLEDGEMENTS

Thanks to Just**Me from the BeyondUnreal Forums who gave me a head start with
an example script.
  
Thanks Antonio Cordero for the Unreal Tournament Package File Format
documentation and the Delphi libraries.
  
Thanks to NogginBasher and Blackwolf for helping me test the package and
scripts.
  
AUTHOR

Christiaan ter Veen <mail@rork.nl>
