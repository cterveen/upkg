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


Textures
  
getTexture($objectid) - Returns a hash with the texture properties
  
getPallette($objectid) - Returns a hash with the pallette
  
Meshes
  
getMesh($objectid) - Returns a hash with the mesh properties
  
KNOWN ISSUES

DEVELOPMENT - Development of this package was goal driven. Therefore methods
usually don't return full information but only the required information. More
and different features may be added in the future.

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
