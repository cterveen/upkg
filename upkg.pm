package upkg;

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = 0.1;

sub new {
  my $class = shift;
  my $self = {};
  
  $self->{'debuglog'} = "";
      
  bless($self, $class);
}

sub load {
  my $self = shift;
  my $file = shift;
  
  $self->{'debuglog'} .= "Open $file\n";
  open($self->{'fh'}, "<", $file) or die "Can't open $file: $!";
  $self->getHeaders();
  
  # Optionally, ignore for now
  #   if ($self->{headers}->{"Signature"} ne "9e2a83c1") {
  #     # die "Invallid file";
  #   }
  $self->getNames();
  $self->getImports();
  $self->getImportNames();
  $self->getExports();
  $self->getExportNames();
}

sub debugLog {
  my $self = shift;
  
  my $log;
  my %headers = %{$self->{'headers'}};
  $log .= "Signature: " . $headers{"Signature"} ."\n";
  $log .= "Version: " . $headers{"Version"} ."\n";
  $log .= "License: " . $headers{"License"} ."\n";
  $log .= "Flag: " . $headers{"Flag"} ."\n";
  $log .= "Name Count: " . $headers{"NameCount"} ."\n";
  $log .= "Name Offset: " . $headers{"NameOffset"} ."\n";
  $log .= "Export Count: " . $headers{"ExportCount"} ."\n";
  $log .= "Export Offset: " . $headers{"ExportOffset"} ."\n";
  $log .= "Import Count: " . $headers{"ImportCount"} ."\n";
  $log .= "Import Offset: " . $headers{"ImportOffset"} ."\n";

  # only print the GUID if the version >= 68
  if ($headers{"Version"} >= 68) {
    $log .= "GUID: " . $headers{"GUID"} ."\n"; 
  }
  
  my @names = @{$self->{'names'}};
  for (my $i = 0; $i < $headers{"NameCount"}; $i++) {
    $log .= "Name $i: " . $names[$i]->{"Name"} ."\n";
  }
  
  my @imports = @{$self->{'imports'}};
  for (my $i = 0; $i < $headers{"ImportCount"}; $i++) {
    $log .= "Import $i: ";
    $log .= join(".", $imports[$i]->{"_uPackage"}, $imports[$i]->{"_uName"}, $imports[$i]->{"_Package"}, $imports[$i]->{"_Name"}) ."\n";
  }
  
  my @exports = @{$self->{'exports'}};
  for (my $i = 0; $i < $headers{"ExportCount"}; $i++) {
    $log .= "Export $i: ";
    $log .= join(".", $exports[$i]->{"_Package"}, $exports[$i]->{"_Super"}, $exports[$i]->{"_Class"}, $exports[$i]->{"_Name"});
    $log .= " at $exports[$i]->{offset}, size: $exports[$i]->{Size}, flags: $exports[$i]->{Flags}\n";
  }
  
  $log .= $self->{'debuglog'};
  
  return $log;
}

sub getDependencies {
  my $self = shift;
  my @dependencies;
  
  # this subroutine can probably be written a lot better but this will do for now.
  for (my $i = 0; $i < $self->{'headers'}->{"ImportCount"}; $i++) {
    if ($self->{'imports'}->[$i]->{"Package"} == 0) {
      # now we have a package;
      for(my $x = 0; $x < $self->{'headers'}->{"ImportCount"}; $x++) {
        if ($self->{'imports'}->[$i]->{"_Name"} eq $self->{'imports'}->[$x]->{"_Package"}) {
          # there must be some hidden character for I can only use a regexp and not an exact match;
          if ($self->{'imports'}->[$x]->{"_uName"} =~ m/Class/) {
            $self->{'imports'}->[$i]->{"Type"} = ".u";
            last;
          }
          elsif ($self->{'imports'}->[$x]->{"_uName"} =~ m/Texture/) {
            $self->{'imports'}->[$i]->{"Type"} = ".utx";
          }
          elsif ($self->{'imports'}->[$x]->{"_uName"} =~ m/Sound/) {
            $self->{'imports'}->[$i]->{"Type"} = ".uax";
          }
          elsif ($self->{'imports'}->[$x]->{"_uName"} =~ m/Music/) {
            $self->{'imports'}->[$i]->{"Type"} = ".umx";
          }
	  else {
            # another deeper search for the origin of a package;
            foreach (my $y = 0; $y < $self->{'headers'}->{"ImportCount"}; $y++) {
              if ($self->{'imports'}->[$x]->{"_Name"} eq $self->{'imports'}->[$y]->{"_Package"}) {
                if ($self->{'imports'}->[$y]->{"_uName"} =~ m/Class/) {
                  $self->{'imports'}->[$i]->{"Type"} = ".u";
                  last;
                }
                elsif ($self->{'imports'}->[$y]->{"_uName"} =~ m/Texture/) {
                  $self->{'imports'}->[$i]->{"Type"} = ".utx";
                }
                elsif ($self->{'imports'}->[$y]->{"_uName"} =~ m/Sound/) {
                  $self->{'imports'}->[$i]->{"Type"} = ".uax";
                }
                elsif ($self->{'imports'}->[$y]->{"_uName"} =~ m/Music/) {
                  $self->{'imports'}->[$i]->{"Type"} = ".umx";
                }
              }
             }
          }
          # if a package is marked as a non .u file it can also be .u package with some imported stuff
          # if it's an .u there's no need to look further though.
          last if ($self->{'imports'}->[$i]->{"Type"} and $self->{'imports'}->[$i]->{"Type"} eq ".u");
        }
        # same here.
        last if ($self->{'imports'}->[$i]->{"Type"} and $self->{'imports'}->[$i]->{"Type"} eq ".u");
      }
        
      my $package =  $self->{'imports'}->[$i]->{"_Name"};
      if ($self->{'imports'}->[$i]->{"Type"}) {
        $package .= $self->{'imports'}->[$i]->{"Type"};
      }
      else {
        $package .= ".uxx";
      }
      push(@dependencies, $package);
    }
  }
  
  return @dependencies;
}

sub getExportProperties {
  my $self = shift;
  my @properties;
  my $name = $self->getName($self->$self->ReadIndex());
  while($name ne "None") {
    # print "Property: $name";
    my $infoByte;
    read($self->{'fh'}, $infoByte, 1);
    my $type = ($infoByte & (1+2+4+8));
    my $size = ($infoByte & (16+32+64));
    my $flag = ($infoByte & 128);
    # print " $type, $size. $flag\n";


    my $name = $self->getName($self->$self->ReadIndex());
  }
}

sub getExports {
  my $self = shift;
  # skip to the exports table
  seek($self->{'fh'}, $self->{headers}->{"ExportOffset"}, 0);
  for (my $i = 0; $i < $self->{headers}->{"ExportCount"}; $i++) {
    my $class = $self->ReadIndex();
    my $super = $self->ReadIndex();
    my $package = $self->ReadLong();
    my $name = $self->ReadIndex();
    my $flags = $self->ReadLong();
    my $size = $self->ReadIndex();
    my $offset = -1;
    if ($size > 0) {
      $offset = $self->ReadIndex();
    }
    $self->{'exports'}->[$i] = {"offset" => $offset, "Package" => $package, "Super" => $super, "Class" => $class, "Name" => $name, "Size" => $size, "Flags" => $flags, "Id" => $i};
  }
}

sub getExportNames {
  my $self = shift;
  for(my $i = 0; $i < $self->{headers}->{"ExportCount"}; $i++) {
    $self->{'exports'}->[$i]->{"_Package"} = $self->getName($self->{'exports'}->[$i]->{"Package"});
    $self->{'exports'}->[$i]->{"_Super"} = $self->getName($self->{'exports'}->[$i]->{"Super"});

    if ($self->{'exports'}->[$i]->{"Class"} < 0) {
      my $tmp = $self->{'exports'}->[$i]->{"Class"};
      $tmp *= -1;
      $tmp -= 1;
      $self->{'exports'}->[$i]->{"_Class"} = $self->getName($self->{'imports'}->[$tmp]->{"Name"});
    }
    else {
      $self->{'exports'}->[$i]->{"_Class"} = $self->getName($self->{'exports'}->[$i]->{"Class"});
    }
    $self->{'exports'}->[$i]->{"_Name"} = $self->getName($self->{'exports'}->[$i]->{"Name"});
  }
}

sub getHeaders {
  my $self = shift;
  # this shouldn't be an issue, paranoia.
  seek($self->{'fh'}, 0, 0);
  $self->{headers}->{"Signature"} = sprintf("%x", $self->ReadLong());
  $self->{headers}->{"Version"} = $self->ReadShort();
  $self->{headers}->{"License"} = $self->ReadShort();
  $self->{headers}->{"Flag"} = $self->ReadLong();
  $self->{headers}->{"NameCount"} = $self->ReadLong();
  $self->{headers}->{"NameOffset"} = $self->ReadLong();
  $self->{headers}->{"ExportCount"} = $self->ReadLong();
  $self->{headers}->{"ExportOffset"} = $self->ReadLong();
  $self->{headers}->{"ImportCount"} = $self->ReadLong();
  $self->{headers}->{"ImportOffset"} = $self->ReadLong();

  # only get the GUID if the version >= 68
  if ($self->{headers}->{"Version"} >= 68) {
    $self->{headers}->{"GUID"} = sprintf("%08x", $self->ReadLongGUID()) . "-" . sprintf("%08x", $self->ReadLongGUID()) . "-" . sprintf("%08x", $self->ReadLongGUID()) . "-" . sprintf("%08x", $self->ReadLongGUID());
  }
}

sub getImports {
  my $self = shift;
  # skip to the imports table
  seek($self->{'fh'}, $self->{headers}->{"ImportOffset"}, 0);
  for (my $i = 0; $i < $self->{headers}->{"ImportCount"}; $i++) {
    my $offset = tell($self->{'fh'});
    my $class_package = $self->ReadIndex();
    my $class_name = $self->ReadIndex();
    my $package = $self->ReadLong();
    my $name = $self->ReadIndex();
    $self->{'imports'}->[$i] = {"offset" => $offset, "uPackage" => $class_package, "uName" => $class_name, "Package" => $package, "Name" => $name};
  }
}

sub getImportNames {
  my $self = shift;
  for(my $i = 0; $i < $self->{headers}->{"ImportCount"}; $i++) {
    $self->{'imports'}->[$i]->{"_uPackage"} = $self->getName($self->{'imports'}->[$i]->{"uPackage"});
    $self->{'imports'}->[$i]->{"_uName"} = $self->getName($self->{'imports'}->[$i]->{"uName"});
    ## Catch the bug where we fail to parse the file properly, and abort the process instead of looping and spewing errors.
    # if ($self->{'imports'}->[$i]->{"Package"} < 0 || $self->{'imports'}->[$i]->{"Package"} >= 0) {
    # } else {
      # die "getImportNames(): Package is not a number!"
    # }
    # if (!$self->{'imports'}->[$i]->{"Package"}) {
    if ($self->{'imports'}->[$i]->{"Package"} eq "") {
      warn "getImportNames(): \$import[".$i."]->{\"Package\"} has no value; aborting";
      # die "getImportNames(): Package \"" . ($self->{'imports'}->[$i]->{"Package"}) . "\" (".$i.") is not a number; aborting";
    }
    if ($self->{'imports'}->[$i]->{"Package"} < 0) {
      my $tmp = $self->{'imports'}->[$i]->{"Package"};
      $tmp *= -1;
      $tmp -= 1;
      $self->{'imports'}->[$i]->{"_Package"} = $self->getName($self->{'imports'}->[$tmp]->{"Name"});
    }
    else {
      $self->{'imports'}->[$i]->{"_Package"} = $self->getName($self->{'imports'}->[$i]->{"Package"});
    }
    $self->{'imports'}->[$i]->{"_Name"} = $self->getName($self->{'imports'}->[$i]->{"Name"});
  }
}

sub getName {
  my $self = shift;
  my $i = shift;
  if ($i < 0) {
      return "Engine";
  }
  elsif ($i > $#{$self->{'names'}}) {
    return "Error";
  }
  else {
    return $self->{'names'}->[$i]->{"Name"};
  }
}

sub getNames {
  my $self = shift;
  # skip to the name table.
  seek($self->{'fh'}, $self->{headers}->{"NameOffset"}, 0);

  my $object;
  my $length;

  for (my $i = 0; $i < $self->{headers}->{"NameCount"}; $i++) {
    my $name = $self->ReadString();

    my $flag = $self->ReadLong();
    $self->{'names'}->[$i] = { "Name" => $name, "Flag" => $flag }; 
    # $debug && print "$self->getNames: name=" . $object . " flag=" . $object . "\n";
  }
}

sub getObject {
  my $self = shift;
  my $id = shift;
  my $offset = $self->{'exports'}->[$id]->{"offset"};
  my %objects;
  
  $self->{'debuglog'} .= "Get object $id at $offset\n";
  # warn("Get object $id at $offset\n");

  seek($self->{'fh'}, $offset, 0);
    
  # HEADER, should not be read if the object doesn't have an RF_HasStack flag
  my $flags = $self->{'exports'}->[$id]->{"Flags"};
     
  if ($flags & 0x02000000) {
    my $node = $self->ReadIndex();
    my $statenode = $self->ReadIndex();
    my $probemask = $self->ReadQWord();
    my $latentaction = $self->ReadLong();
    if ($node != 0) {
      my $offset = $self->ReadIndex();
    }
  }
  
  # build in savety, loop stops after 256 itterations to prevent eternal loops
  foreach (0 .. 256) {
    my $object = $self->ReadObjectProperty();
    if ($self->getName($object->{'name'}) eq "None") {
      last;
    }
    else {
      my $name = $self->getName($object->{'name'});
      
      # correct arrays
      if ($objects{$name}) {
        my $obj = $objects{$name};
        $objects{$name."[0]"} = $obj;
        delete($objects{$name});
      }
      if ($object->{'i'}) {
        $name .= "[" . $object->{'i'} . "]";
      }
      $objects{$name} = $object;
      
      if ($_ == 256) {
        warn("WARNING: more object properties available\n");
        $self->{'debuglog'} = "WARNING: more object properties available\n";
      }
    }
    
  }
  return %objects;
}

sub getTexture {
  my $self = shift;
  my $id = shift; #id in export table
  
  my %object = $self->getObject($id);
  
  $object{'mipmapcount'}->{value} = $self->ReadByte();
  
  foreach my $mipmap (1 .. $object{'mipmapcount'}->{value}) {
    if ($self->{'headers'}->{'Version'} >= 63) {
       $object{'WidthOffset_' . $mipmap}->{value} = $self->ReadLong();
    }
    $object{'mipmapsize_' . $mipmap}->{value} = $self->ReadIndex();
    
    foreach (1 .. $object{'mipmapsize_' . $mipmap}->{value}) {
      $object{'mipmap_' . $mipmap}->{value} .= $self->ReadByte() . " ";
    }
    
    $object{'width_' . $mipmap}->{value} = $self->ReadLong();
    $object{'height_' . $mipmap}->{value} = $self->ReadLong();
    $object{'bitswidth_' . $mipmap}->{value} = $self->ReadByte();
    $object{'bitsheight_' . $mipmap}->{value} = $self->ReadByte();
    last;
  }
  return %object;
}

sub getPalette {
  my $self = shift;
  my $id = shift;
  
  my %object = $self->getObject($id);
  
  $object{'palettesize'}->{'value'} = $self->ReadIndex();
  
  foreach (1 .. $object{'palettesize'}->{'value'}) {
    $object{$_}->{'value'} = [];
    push($object{$_}->{'value'}, $self->ReadByte(), $self->ReadByte(), $self->ReadByte(), $self->ReadByte());
  }
  
  return %object;
}

sub getPackage {
  my $self = shift;
  my $class = shift;
  
  my @imports = @{$self->{'imports'}};
  
  foreach (@imports) {
    if ((lc($_->{'_uPackage'}) eq "core") && (lc($_->{'_uName'}) eq "class") && (lc($_->{'_Name'}) eq lc($class))) {
      return $_->{'_Package'};
    }
  }
  
  return "Unknown";
}

sub getMesh {
  my $self = shift;
  my $id = shift;
  
  $self->{'debuglog'} .= "Execute getMesh($id)\n";
  
  my %object = $self->getObject($id);
     $object{'raw'}->{'value'} = "Raw data\n";
     $object{'raw'}->{'verts'} = [];
     $object{'raw'}->{'vertindex'} = [];
     $object{'raw'}->{'wedges'} = [];
     $object{'raw'}->{'uvmap'} = [];
     $object{'raw'}->{'textures'} = [];
     $object{'raw'}->{'materials'} = [];
     
  my $version = $self->{'headers'}->{'Version'};
    
  $self->{'debuglog'} .= "   Get BoundingBox & Sphere\n";
  
  $object{'Primitive.BoundingBox'}->{'value'} = join(",", $self->ReadVector(), $self->ReadVector(), $self->ReadByte);
  $object{'Primitive.BoundingSphere'}->{'value'} = $self->ReadVector();

  
  if ($version > 61) {
    $object{'Primitive.BoundingSphere'}->{'value'} .= "," . $self->ReadFloat();
    $object{'Verts_Jump'}->{'value'} = $self->ReadLong();
  }
    
  $self->{'debuglog'} .= "   Get Verts\n";
  $object{'Verts_Count'}->{'value'} = $self->ReadIndex();
  
  foreach (1 .. $object{'Verts_Count'}->{'value'}) {
    my $xyz = $self->ReadDWord();
    my $x = ($xyz & 0x7FF)/8;
    my $y = (($xyz >> 11) & 0x7FF)/8;
    my $z = (($xyz >> 22) & 0x3FF)/4;
    
    if ($x > 128) { $x = $x - 256}
    $x *= -1;
    if ($y > 128) { $y = $y - 256}
    $y *= -1;
    if ($z > 128) { $z = $z - 256}
    $z *= -1;
    $object{"Vert_" . $_}->{'value'} = "(X=$x; Y=$y; Z=$z)";
    push(@{$object{'raw'}->{'verts'}}, [$x, $y, $z]);
  }
  
  $self->{'debuglog'} .= "   Get Tris\n";
  if ($version > 61) {
    $object{'Tris_Jump'}->{'value'} = $self->ReadLong();
  }
  $object{'Tris_Count'}->{'value'} = $self->ReadIndex();
  
  foreach (1 .. $object{'Tris_Count'}->{'value'}) {
    $object{'VertexIndex1_' . $_}->{'value'} = $self->ReadShort();
    $object{'VertexIndex2_' . $_}->{'value'} = $self->ReadShort();
    $object{'VertexIndex3_' . $_}->{'value'} = $self->ReadShort();
    $object{'VertexI1_U_' . $_}->{'value'} = $self->ReadByte();
    $object{'VertexI1_V_' . $_}->{'value'} = $self->ReadByte();
    $object{'VertexI2_U_' . $_}->{'value'} = $self->ReadByte();
    $object{'VertexI2_V_' . $_}->{'value'} = $self->ReadByte();
    $object{'VertexI3_U_' . $_}->{'value'} = $self->ReadByte();
    $object{'VertexI3_V_' . $_}->{'value'} = $self->ReadByte();
  }
  
  $self->{'debuglog'} .= "   Get Anims\n";
  
  $object{'AnimSeqs_Count'}->{'value'} = $self->ReadIndex();
  
  foreach my $i (1 .. $object{'AnimSeqs_Count'}->{'value'}) {
    $object{'Name_' . $i}->{'value'} = $self->ReadIndex();
    $object{'Group_' . $i}->{'value'} = $self->ReadIndex();
    $object{'Start_Frame_' . $i}->{'value'} = $self->ReadLong();
    $object{'Num_Frames_' . $i}->{'value'} = $self->ReadLong();
    $object{'Function_Count_' . $i}->{'value'} = $self->ReadIndex();
    foreach (1 .. $object{'Function_Count_' . $i}->{'value'}) {
      $object{'Time_' . $i . "_" . $_}->{'value'} = $self->ReadLong();
      $object{'Function_' . $i . "_" . $_}->{'value'} = $self->ReadIndex();
    }
    $object{'Rate_' . $i}->{'value'} = $self->ReadFloat();    
  }
  
  $self->{'debuglog'} .= "   Get Connects\n";
  $object{'Connects_Jump'}->{'value'} = $self->ReadDWord();
  $object{'Connects_Count'}->{'value'} = $self->ReadIndex();
  
  foreach (1 .. $object{'Connects_Count'}->{'value'}) {
    $object{'NumVerTriangles_' . $_}->{'value'} = $self->ReadDWord();
    $object{'TriangleListOfset_'}->{'value'} = $self->ReadDWord();
  }
  
  $self->{'debuglog'} .= "   Get another bounding box and sphere\n";
  $object{'BoundingBox'}->{'value'} = join(",", $self->ReadVector(), $self->ReadVector(), $self->ReadByte);
  $object{'BoundingSphere'}->{'value'} = $self->ReadVector();
  if ($version > 61) {
     $object{'BoundingSphere'}->{'value'} .= "," . $self->ReadFloat();
  }
    
  $self->{'debuglog'} .= "   Get vertlink links\n";
  $object{'VertLinks_Jump'}->{'value'} = $self->ReadDWord();
  $object{'VertLinks_Count'}->{'value'} = $self->ReadIndex();
  
  foreach (1 .. $object{'VertLinks_Count'}->{'value'}) {
    $object{'VertLink_' . $_}->{'value'} = $self->ReadDWord();
  }

  $self->{'debuglog'} .= "   Get textures\n";
  $object{'Texture_Count'}->{'value'} = $self->ReadIndex();
  
  foreach (1 .. $object{'Texture_Count'}->{'value'}) {
    $object{'Texture_' . $_}->{'value'} = $self->ReadIndex();
    push(@{$object{'raw'}->{'textures'}}, $object{'Texture_' . $_}->{'value'});
  }
  
  $self->{'debuglog'} .= "   Get boundingboxes\n";
  $object{'BoundingBoxes_Count'}->{'value'} = $self->ReadIndex();
  
  foreach (1 .. $object{'BoundingBoxes_Count'}->{'value'}) {
    $object{'BoundingBoxes_' . $_}->{'value'} = join(",", $self->ReadVector(), $self->ReadVector(), $self->ReadByte);
  }
  
  $self->{'debuglog'} .= "   Get boundingspheres\n";
  $object{'BoundingSpheres_Count'}->{'value'} = $self->ReadIndex();
  
  foreach (1 .. $object{'BoundingSpheres_Count'}->{'value'}) {
    $object{'BoundingSpheres_' . $_}->{'value'} = $self->ReadVector();
      
    if ($version > 61) {
      $object{'BoundingSpheres_' . $_}->{'value'} .= "," . $self->ReadFloat();
    }
  }
  
  $self->{'debuglog'} .= "   Get others\n";
  
  $object{'FrameVerts'}->{'value'} = $self->ReadDWord();
  $object{'AnimFrames'}->{'value'} = $self->ReadDWord();
  $object{'ANDFlags'}->{'value'} = $self->ReadDWord();
  $object{'ORFlags'}->{'value'} = $self->ReadDWord();
  $object{'Scale'}->{'value'} = $self->ReadVector();
  $object{'Origin'}->{'value'} = $self->ReadVector();
  $object{'RotOrigin'}->{'value'} = $self->ReadRotator();
  $object{'CurPoly'}->{'value'} = $self->ReadDWord();
  $object{'CurVertex'}->{'value'} = $self->ReadDWord();
  
  if ($version == 65) {
    $object{'TextureLOD?'}->{'value'} = $self->ReadFloat();
  }
  elsif ($version >= 66) {
    $object{'TextureLOD_Count'}->{'value'} = $self->ReadIndex();
    foreach (1 .. $object{'TextureLOD_Count'}->{'value'}) {
      $object{'TextureLOD_' . $_}->{'value'} = $self->ReadFloat();
    }
  }
  
  # LODMesh?
  if ($object{'Tris_Count'}->{'value'} != 0) {
    return %object;
  }
  
  $self->{'debuglog'} .= "   Get CollapsePointThus\n";
  $object{'CollapsePointThus_Count'}->{'value'} = $self->ReadIndex();
  
  foreach (1 .. $object{'CollapsePointThus_Count'}->{'value'}) {
    $object{'CollapsePointThus_' . $_}->{'value'} = $self->ReadWord();
  }
  
  $self->{'debuglog'} .= "   Get FaceLevel\n";
  $object{'FaceLevel_Count'}->{'value'} = $self->ReadIndex();
  
  foreach (1 .. $object{'FaceLevel_Count'}->{'value'}) {
    $object{'FaceLevel_' . $_}->{'value'} = $self->ReadWord();
  }
  
  $self->{'debuglog'} .= "   Get Faces\n";
  $object{'Faces_Count'}->{'value'} = $self->ReadIndex();
  
  foreach (1 .. $object{'Faces_Count'}->{'value'}) {
    $object{'WedgeIndex1_' . $_}->{'value'} = $self->ReadWord();
    $object{'WedgeIndex2_' . $_}->{'value'} = $self->ReadWord();
    $object{'WedgeIndex3_' . $_}->{'value'} = $self->ReadWord();
    $object{'MaterialIndex_' . $_}->{'value'} = $self->ReadWord();
    
    
    push(@{$object{'raw'}->{'wedges'}}, [$object{'WedgeIndex1_' . $_}->{'value'},  $object{'WedgeIndex2_' . $_}->{'value'}, $object{'WedgeIndex3_' . $_}->{'value'}, $object{'MaterialIndex_' . $_}->{'value'}]);
  }
  
  $self->{'debuglog'} .= "   Get CollapseWedgeThus\n";
  $object{'CollapseWedgeThus_Count'}->{'value'} = $self->ReadIndex();
  
  foreach (1 .. $object{'CollapseWedgeThus_Count'}->{'value'}) {
    $object{'CollapseWedgeThus_' . $_}->{'value'} = $self->ReadWord();
  }
  
  $self->{'debuglog'} .= "   Get Wedges\n";
  $object{'Wedges_Count'}->{'value'} = $self->ReadIndex();
  
  foreach (1 .. $object{'Wedges_Count'}->{'value'}) {
    $object{'VertexIndex_' . $_}->{'value'} = $self->ReadWord();
    $object{'S_' . $_}->{'value'} = $self->ReadByte();
    $object{'T_' . $_}->{'value'} = $self->ReadByte();
    push(@{$object{'raw'}->{'vertindex'}}, $object{'VertexIndex_' . $_}->{'value'});
    push(@{$object{'raw'}->{'uvmap'}}, [($object{'S_' . $_}->{'value'}/255), (1-$object{'T_' . $_}->{'value'}/255)]);
  }
  
  $self->{'debuglog'} .= "   Get Materials\n";
  $object{'Materials_Count'}->{'value'} = $self->ReadIndex();
  
  foreach (1 .. $object{'Materials_Count'}->{'value'}) {
    $object{'Flags_' . $_}->{'value'} = $self->ReadDWord();
    $object{'TextureIndex' . $_}->{'value'} = $self->ReadDWord();
   push(@{$object{'raw'}->{'materials'}}, $object{'TextureIndex' . $_}->{'value'});
  }
  
  $self->{'debuglog'} .= "   Get SpecialFaces\n";
  $object{'SpecialFaces_Count'}->{'value'} = $self->ReadIndex();
  
  foreach (1 .. $object{'SpecialFaces_Count'}->{'value'}) {
    $object{'SpecialWedgeIndex1_' . $_}->{'value'} = $self->ReadWord();
    $object{'SpecialWedgeIndex2_' . $_}->{'value'} = $self->ReadWord();
    $object{'SpecialWedgeIndex3_' . $_}->{'value'} = $self->ReadWord();
    $object{'SpecialMaterialIndex4_' . $_}->{'value'} = $self->ReadWord();
  }
  
  $self->{'debuglog'} .= "   Get Other\n";
  $object{'ModelVerts'}->{'value'} = $self->ReadDWord();
  $object{'SpecialVerts'}->{'value'} = $self->ReadDWord();
  $object{'MeshScaleMax'}->{'value'} = $self->ReadFloat();
  $object{'LODHysterisis'}->{'value'} = $self->ReadFloat();
  $object{'LODStrength'}->{'value'} = $self->ReadFloat();
  $object{'LODMinVerts'}->{'value'} = $self->ReadDWord();
  $object{'LODMorph'}->{'value'} = $self->ReadFloat();
  $object{'LODZDisplace'}->{'value'} = $self->ReadFloat();

  $self->{'debuglog'} .= "   Get ReMapAnimVerts\n";
  $object{'ReMapAnimVerts_Count'}->{'value'} = $self->ReadIndex();
  
  foreach (1 .. $object{'ReMapAnimVerts_Count'}->{'value'}) {
    $object{'ReMapAnimVerts_' . $_}->{'value'} = $self->ReadWord();
  }
  $object{'OldFrameVerts'}->{'value'} = $self->ReadDWord();
  
  return %object;
  
}

sub ReadRotator {
  my $self = shift;
     $self->{'debuglog'} .= "Read Rotator (3x dword)\n";
     
  my $pitch = $self->ReadDWord();
  my $jaw = $self->ReadDWord();
  my $roll = $self->ReadDWord();
  
  my $rotator = "(Pitch=$pitch, Jaw=$jaw, Roll=$roll)";
 
  $self->{'debuglog'} .= "<- Read rotator at " . (tell($self->{'fh'})-12) . ": " . $rotator . "\n";
  
  return $rotator; 
  
}

sub ReadIndex {
  my $self = shift;
  # read an index coded section from MAP, I really have no idea what I'm doing
  # here, just copied the code from the original script but it seems to work ok

  my $buffer;
  my $neg;
  my $length = 6;
  my $start = tell($self->{'fh'});

  for(my $i = 0; $i < 5; $i++) {
    my $more = 0;
    my $char;
    read($self->{'fh'}, $char, 1);
    $char = vec($char, 0, 8);

    if ($i == 0) {
      $neg = ($char & 0x80);
      $more = ($char & 0x40);
      $buffer = ($char & 0x3F);
    }
    elsif ($i == 4) {
      $buffer |= ($char & 0x80) << $length;
      $more = 0;
    }
    else {
     $more = ($char & 0x80);
     $buffer |= ($char & 0x7F) << $length;
     $length += 7;
    }
    # print " --> $buffer ";
    last unless ($more);
  }

  if ($neg) {
    $buffer *= -1;
  }

  # print "ReadIndex returning buffer: " . $buffer . "\n";
  
  $self->{'debuglog'} .= "<- Read index at " . $start . ": " . $buffer . "\n";
  
  return $buffer;
}

sub ReadString {
  my $self = shift;
  # series of unicode characters finshed by a zero
  
  my $string;
  my $char = 1;
  
  my $start = tell($self->{'fh'});
  
  # if package version >= 64 the sting starts with the length; assuming this is an index.
  if ($self->{headers}->{"Version"} >= 64) {
    my $size = $self->ReadIndex();
    if ($size <= 0) {
      warn("0 or negative length on readstring at " . tell($self->{'fh'}));
      $self->{'debuglog'} .= "0 or negative length on readstring at " . tell($self->{'fh'}) . "\n";
      # fall back to the old system
      $char = 1;
      while (ord($char) != 0) {
	read($self->{'fh'}, $char, 1);
	$string .= $char;
      }
    }
    else {
      read($self->{'fh'}, $string, $size);
    }
  }
  else {
    $char = 1;
    while (ord($char) != 0) {
      read($self->{'fh'}, $char, 1);
      $string .= $char;
    }
  }

  # remove the last zerobyte character
  chop($string);
  
  $self->{'debuglog'} .= "<- Read string at " . $start . ": " . $string . "\n";
  
  return $string; 
}

sub ReadObjectProperty {
  my $self = shift;
  my $object;
  my $char;
  
  $self->{'debuglog'} .= ">Read objectproperty\n";
    
  # Offset (current position)
  $object->{'offset'} = sprintf("%x", tell);
    
  # INDEX - Name
  $object->{'name'} = $self->ReadIndex();
  
  if ($self->getName($object->{'name'}) eq "None") {
    return $object;
  }
  
  $self->{'debuglog'} .= ">name=". $self->getName($object->{'name'}) . "\n";
  
  # BYTE - Infobyte
  read($self->{'fh'}, $char, 1);
  $char = vec($char, 0, 8);
    
  $object->{'type'} = ($char & 0b00001111);
  $object->{'sizetype'} = ($char & 0b01110000) >> 4;
  $object->{'arrayflag'} = ($char & 0x80);
  
  $self->{'debuglog'} .= ">type=". $object->{'type'} . "\n";
  $self->{'debuglog'} .= ">sizetype=". $object->{'sizetype'} . "\n";
  $self->{'debuglog'} .= ">arrayflag=". $object->{'arrayflag'} . "\n";
  
  # if arrayflag is set, next is the position of the array
  if (($object->{'arrayflag'}) and ($object->{'type'} != 3)) {
    # WARNING if i >128 terrible things will happen
    $object->{'i'} = $self->ReadByte();
  }
  
  # if type is a struct the next byte will be the structname, assuming this is an INDEX
  if ($object->{'type'} == 10) {
    $object->{'structname'} = $self->getName($self->ReadIndex());
  }
  
  # Get the size
  if ($object->{'sizetype'} == 0) {
    $object->{'size'} = 1;
  }
  elsif ($object->{'sizetype'} == 1) {
    $object->{'size'} = 2;
  }
  elsif ($object->{'sizetype'} == 2) {
    $object->{'size'} = 4;
  }
  elsif ($object->{'sizetype'} == 3) {
    $object->{'size'} = 12;
  }
  elsif ($object->{'sizetype'} == 4) {
    $object->{'size'} = 16;
  }
  elsif ($object->{'sizetype'} == 5) {
    # byte
    $object->{'size'} = $self->ReadByte();
  }
  elsif ($object->{'sizetype'} == 6) {
    # word --> ReadShort
   $object->{'size'} = $self->ReadShort();
  }
  elsif ($object->{'sizetype'} == 7) {
    # integer --> 32 bits (as UT was build for 32 bits) --> 4 bytes --> DWORD --> Long
    $object->{'size'} = $self->ReadLong();
  }
    
    
  # Add: 0, 8, 9, 11, 14, 15    
    
  # OBJECT DATA
  $object->{'valueoffset'} = tell($self->{'fh'});
  
  if ($object->{'type'} == 1) {
    # BYTE - byte
    $object->{'value'} = $self->ReadByte();
  }
  elsif ($object->{'type'} == 2) {
    # DWORD Integer
    $object->{'value'} = $self->ReadLong();
  }
  elsif ($object->{'type'} == 3) {
    # BOOLEAN - Byte 7 of the info byte, which coincides with the arrayflag
    $object->{'value'} = $object->{'arrayflag'} / 128;
  }
  elsif ($object->{'type'} == 4) {
    # FLOAT
    $object->{'value'} = $self->ReadFloat();
  }
  elsif ($object->{'type'} == 5) {
    # INDEX - Objectproperty
    $object->{'value'} = $self->ReadIndex();
        
    if ($object->{'value'} < 0) {
      my $import_id = ($object->{'value'} + 1)*-1;
      $object->{'_value'} = " (" . $self->{'imports'}->[$import_id]->{'_Package'} . "." . $self->{'imports'}->[$import_id]->{'_Name'} . ")";
    }
    else {
      my $export_id = $object->{'value'} - 1;
      $object->{'_value'} = " (" . $self->{'exports'}->[$export_id]->{'_Class'} . "." . $self->{'exports'}->[$export_id]->{'_Name'} . ")";
    }
  }
  elsif ($object->{'type'} == 6) {
    # INDEX - Nameproperty
    $object->{'value'} = $self->ReadIndex();
    $object->{'_value'} = " (" . $self->getName($object->{'value'}) . ")";
  }
  elsif ($object->{'type'} == 7) {
    # NAME - String
    $object->{'value'} = $self->ReadString();
  }
  elsif ($object->{'type'} == 10) {
    # Struct name, followed by values
    if (lc($object->{'structname'}) eq "pointregion") {
      # INDEX zone, DWORD ileaf, BYTE zonenumber
      my $zone = $self->ReadIndex();
      my $ileaf = $self->ReadLong();
      my $zonenumber = $self->ReadByte();
      
      $object->{'value'} = "(zone=$zone; ileaf=$ileaf; zonenumber=$zonenumber)";
      $object->{'zone'} = $zone;
      $object->{'ileaf'} = $ileaf;
      $object->{'zonenumber'} = $zonenumber;
    }
    elsif (lc($object->{'structname'}) eq "vector") {
      my $x = $self->ReadFloat();
      my $y = $self->ReadFloat();
      my $z = $self->ReadFloat();
      
      $object->{'value'} = "(X=$x; Y=$y; Z=$z)";
      $object->{'x'} = $x;
      $object->{'y'} = $y;
      $object->{'z'} = $z;
    }
    elsif (lc($object->{'structname'}) eq "color") {
      my $r = $self->ReadByte();
      my $g = $self->ReadByte();
      my $b = $self->ReadByte();
      my $a = $self->ReadByte();
      
      $object->{'value'} = "(R=$r; G=$g; B=$b; A=$a)";
    }
    elsif (lc($object->{'structname'}) eq "rotator") {
      my $pitch = $self->ReadLong();
      my $yaw = $self->ReadLong();
      my $roll = $self->ReadLong();
      
      $object->{'value'} = "(Pitch=$pitch; Yaw=$yaw; Roll=$roll)";
      $object->{'pitch'} = $pitch;
      $object->{'yaw'} = $yaw;
      $object->{'roll'} = $roll;
    }
    elsif (lc($object->{'structname'}) eq "scale") {
      my $x = $self->ReadFloat();
      my $y = $self->ReadFloat();
      my $z = $self->ReadFloat();
      my $sheerrate = $self->ReadLong();
      my $sheeraxis = $self->ReadByte();
      
      $object->{'value'} = "(X=$x; Y=$y; Z=$z; Sheerrate=$sheerrate; Sheeraxis=$sheeraxis)";
      $object->{'x'} = $x;
      $object->{'y'} = $y;
      $object->{'z'} = $z;
      $object->{'sheerrate'} = $sheerrate;
      $object->{'sheeraxis'} = $sheeraxis;
    }
    else {
      warn("Unknown struct: '" . $object->{'structname'} . "'\n");
      read($self->{'fh'}, $char, $object->{'size'});
    }
  }
  elsif ($object->{'type'} == 13) {
    # string;
    $object->{'value'} = $self->ReadString();
  }
  else {
    warn("Unknown object type: ". $object->{'type'} . " at " . $object->{'offset'} . "\n");
    read($self->{'fh'}, $char, $object->{'size'});
    $object->{'value'} = $char;
  }
  
  # debuglog
  foreach my $key (sort keys %{$object}) {
    $self->{'debuglog'} .= "  " . $key . " = " . $object->{$key} . "\n";
  }
  
  
  # check if we're at the end
  my $current_position = tell($self->{'fh'});
  my $expected_position = $object->{'valueoffset'} + $object->{'size'};

  if ($current_position != $expected_position) {
    warn("Wrong position: $current_position where $expected_position expected");
    $self->{'debuglog'} .= "Wrong position: $current_position where $expected_position expected\n";
    seek($self->{'fh'}, $expected_position, 0);
  }
  $self->{'debuglog'} .= "  --\n";
  
  # print $current_position . "\n";
  return $object;
}

sub ReadByte {
  my $self = shift;
  my $string;
  read($self->{'fh'}, $string, 1);
  $string = vec($string, 0, 8);
  my $byte = ($string & 0xFF);
  
  $self->{'debuglog'} .= "<- Read byte at " . (tell($self->{'fh'})-1) . ": " . $byte . "\n";
  
  return $byte;
}

sub ReadQWord {
  my $self = shift;
  my $string;
  my $char = read($self->{'fh'}, $string, 8);
  my $qword = unpack("B64", $string);
  
  $self->{'debuglog'} .= "<- Read qword at " . (tell($self->{'fh'})-8) . ": " . $qword . "\n";
  
  return $qword;
}

sub ReadDWord {
  my $self = shift;
    return $self->ReadLong();
}

sub ReadWord {
  my $self = shift;  
  return $self->ReadShort();
}

sub ReadLong {
  my $self = shift;
  my $string;
  my $char = read($self->{'fh'}, $string, 4);
  my $long = unpack("l", $string);
  
  $self->{'debuglog'} .= "<- Read dword at " . (tell($self->{'fh'})-4) . ": " . $long . "\n";
  
  return $long;
}

sub ReadLongGUID {
  my $self = shift;
  my $string;
  my $char = read($self->{'fh'}, $string, 4);
  my $long = unpack("L", $string);
  
  $self->{'debuglog'} .= "<- Read GUID dword at " . (tell($self->{'fh'})-4) . ": " . $long . "\n";
  
  return $long;
}

sub ReadShort {
  my $self = shift;
  my $string;
  read($self->{'fh'}, $string, 2);
  my $short = unpack("S", $string);
  
  $self->{'debuglog'} .= "<- Read word at " . (tell($self->{'fh'})-2) . ": " . $short . "\n";
  
  return $short;
}

sub ReadFloat {
  my $self = shift;
  
  my $string;
  read($self->{'fh'}, $string, 4);
  my $float = sprintf("%.2f", unpack("f", $string));
  
  $self->{'debuglog'} .= "<- Read float at " . (tell($self->{'fh'})-4) . ": " . $float . "\n";
  
  return $float;
}

sub ReadVector {
  my $self = shift;
  
  $self->{'debuglog'} .= "-> Read vector at " . tell($self->{'fh'}) . ": 3 floats (X, Y, Z)\n";
   
  my $x = $self->ReadFloat();
  my $y = $self->ReadFloat();
  my $z = $self->ReadFloat();
      
  return "(X=$x; Y=$y; Z=$z)";
}

=head1 NAME

upkg - extract information from Unreal Tournament packages

=head1 SYNOPSIS

use upkg;
  
my $pkg = upkg->new();
   $pkg->load("CTF-Face.unr");
     
print join("\n", $pkg->getDependencies());
  
=head1 DESCRIPTION

This module is used to extract information from Unreal Tournament '99 packages.
Extraction of basic information like the head, name, import and export table is
implemented as well as extraction of some specific objects (see below);
  
=head1 METHODS

=head2 General methods

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


=head2 Textures
  
getTexture($objectid) - Returns a hash with the texture properties
  
getPallette($objectid) - Returns a hash with the pallette
  
=head2 Meshes
  
getMesh($objectid) - Returns a hash with the mesh properties
  
=head1 KNOWN ISSUES

DEVELOPMENT - Development of this package was goal driven. Therefore methods
usually don't return full information but only the required information. More
and different features may be added in the future.

OTHER GAMES - Although the same game engine and package file format is used
for multiple games upkg has not been made for or tested on packages other than
for Unreal Tournament '99 (package version 68).
  
=head1 COPYRIGHTS & DISCLAIMER

You have the right to copy this script, you may also redistribute, adapt and
rewrite it if you want. I can't be held responsible for any damage of this
script did to your system, especially not when they are redistributed or
addapted by other persons. Use the script at your own risk.
  
=head1 ACKNOWLEDGEMENTS

Thanks to Just**Me from the BeyondUnreal Forums who gave me a head start with
an example script.
  
Thanks Antonio Cordero for the Unreal Tournament Package File Format
documentation and the Delphi libraries.
  
Thanks to NogginBasher and Blackwolf for helping me test the package and
scripts.
  
=head1 AUTHOR

Christiaan ter Veen <mail@rork.nl>

=cut

1;
