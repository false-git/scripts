#!/usr/bin/env perl

use strict;
use Image::Magick;
use Image::ExifTool;
use File::Copy;
use File::Path;
use File::stat;
use YAML::XS;
use FindBin;

my $conf = YAML::XS::LoadFile($FindBin::Bin . "/photocp.yaml");

my $SRC_LIBRARY = $conf->{source_library};
my $MASTER = "$SRC_LIBRARY/Masters";
my $PREVIEW = "$SRC_LIBRARY/Previews";

my $DST_PIC_MASTER = $conf->{picture_master};
my $DST_PIC_PREVIEW = $conf->{picture_preview};
my $DST_MOVIE = $conf->{movie_master};

my $LAST = "$SRC_LIBRARY/photocp.last";

sub getSources {
    my $root = shift;
    my $subdir = shift;
    my $lastfile = shift;
    my $dh;
    my @result;
    opendir($dh, "$root$subdir") or die($!);
    my @list = readdir($dh);
    closedir($dh);
    foreach my $file (sort @list) {
	next if ($file =~ /^\.\.?$/);
	if (-d "$root$subdir/$file") {
	    push @result, getSources($root, "$subdir/$file", $lastfile);
	} else {
	    if ($lastfile lt "$subdir/$file") {
		push @result, "$subdir/$file";
	    }
	}
    }
    return @result;
}

sub getYmd {
    my $file = shift;
    my ($y, $m, $d);
    my $exif = new Image::ExifTool;
    my $info = $exif->ImageInfo($file);
    my $value = $info->{'DateTimeOriginal'} // $info->{'CreateDate'} // $info->{'FileModifyDate'};
    if ($value =~ /(\d{4})[:\/-](\d{2})[:\/-](\d{2})/) {
	($y, $m, $d) = ($1, $2, $3);
    } else {
	die($file);
    }
    return ($y, $m, $d);
}

sub getNextFile {
    my $path = shift;
    my $prefix = shift;
    my $ext = shift;
    my $n = 1;
    while (1) {
	my $file = sprintf("%s%03d%s", $prefix, $n++, $ext);
	if (!-e "$path/$file") {
	    return $file;
	}
    }
}

my $lastfile;

if (-f $LAST) {
    open(my $fh, "<", $LAST) or die($!);
    $lastfile = <$fh>;
    close($fh);
}

my @r = getSources($MASTER, "", $lastfile);
my $im = Image::Magick -> new;

foreach my $file (@r) {
    print "$file...";
    my $sourcefile = "$MASTER$file";
    my ($y, $m, $d) = getYmd($sourcefile);
    my $stat = stat($sourcefile);
    if ($file =~ /(\.jpg|\.png)$/i) {
	my $ext = $1;
	my $subdir = sprintf("/%04d/%04d%02d/%04d%02d%02d", $y, $y, $m, $y, $m, $d);
	my $prefix = sprintf("pic%04d%02d%02d-", $y, $m, $d);
	mkpath("$DST_PIC_MASTER$subdir");
	my $target = getNextFile("$DST_PIC_MASTER$subdir", $prefix, $ext);
	my $destinationfile = "$DST_PIC_MASTER$subdir/$target";
	my $ret = copy($sourcefile, $destinationfile);
	if (! defined $ret) {
	    print "master cp failed\n";
	    next;
	}
	utime($stat->atime, $stat->mtime, $destinationfile);
	my $preview = "$PREVIEW$file";
	if (!-e $preview) {
	    $preview = "$MASTER$file";
	}
	$destinationfile = "$DST_PIC_PREVIEW$subdir/$target";
	mkpath("$DST_PIC_PREVIEW$subdir");
	$im->Read($preview);;
	$im->Minify();
	$im->Write($destinationfile);
	@$im = ();
	utime($stat->atime, $stat->mtime, $destinationfile);
	print "done";
    } elsif ($file =~ /(\.mov)$/i) {
	my $ext = $1;
	my $subdir = sprintf("/%04d/%04d%02d", $y, $y, $m);
	my $prefix = sprintf("mov%04d%02d%02d-", $y, $m, $d);
	mkpath("$DST_MOVIE$subdir");
	my $target = getNextFile("$DST_MOVIE$subdir", $prefix, $ext);
	my $destinationfile = "$DST_MOVIE$subdir/$target";
	my $ret = copy($sourcefile, $destinationfile);
	if (! defined $ret) {
	    print "master cp failed\n";
	    next;
	}
	utime($stat->atime, $stat->mtime, $destinationfile);
	print "done";
    } else {
	print "not supported yet.\n";
	next;
    }
    print "\n";
    $lastfile = $file;
}

open(my $fh, ">", $LAST) or die($!);
print $fh "$lastfile";
close($fh);
