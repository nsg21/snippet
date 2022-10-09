#!/usr/bin/perl -W
=head1 NAME

snippet.pl -- extract embedded snippet files from C<notes.txt>

=head1 SYNOPSIS

snippet.pl [internal-snippet-name]

=cut
use strict;
use Getopt::Std;

our(
  $opt_w, # write snippet to disk
  $opt_i, # input file name, default notes.txt
  $opt_o, # output file name, default same as internal
  $opt_l, # list snippets and tehir names
  $opt_c, # TODO: enable contained snippets
  $opt_t, # list nippets of given tag (e.g. File: or Action:)
  $opt_f, # shortcut for -t file
  $opt_a, # shortcut for -t action
  $opt_d, # debug
);

getopts('wi:o:lt:fad');

$opt_t='file' if $opt_f;
$opt_t='action' if $opt_a;
$opt_t||='';
if( '' ne $opt_t ) {
  $opt_t.=':' if( ':' ne substr($opt_t,-1,1) );
}

use File::Spec;

if( !defined($opt_i) ) {

# used to be Cwd::abs_path("notes.txt") here, turns out Cwd returns path with
# symlinks resolved. I needed to preserve symlinks in the path, so changig it
# to relying on PWD env variable.
my $f=File::Spec->catfile($ENV{PWD},"notes.txt");
my ($volume,$path,$name)=File::Spec->splitpath($f);
my @dirs=File::Spec->splitdir($path);
die unless "" eq pop(@dirs);
warn "path=$path dirs=".join(':',@dirs) if $opt_d;
while(@dirs) {
  my $f=File::Spec->catfile( @dirs, $name );
  warn "Try $f\n" if $opt_d;
  if( -f $f ) {
    $opt_i=$f;
    last;
  }
  pop(@dirs);
}
die "File notes.txt is not found in this directory and its parents" if !defined($opt_i);
}

sub isMatchingTag { $opt_t eq '' || lc($opt_t) eq lc($_[0]) }

sub list_snippets
{
  while(<INPUT>){
    if( /^(?:#|--|\/\/)?\s*((?<tag>(?i:[-_a-z]+:)?)\s*.*\S)\s*\{\{\{/ ) {
      print $1,$/ if isMatchingTag(lc($+{tag}));
    }
  }
}

sub extract_snippet
{
my $internalname=shift();
$opt_w=1 if $opt_o ;
$opt_o||=$internalname if $opt_w;

open OUTP, ">", $opt_o if $opt_w;

while(<INPUT>){
  if( (/^(?:#|--|\/\/)?\s*(?<tag>(?i:[-_a-z]+:)?)\s*\Q$internalname\E\s*\{\{\{/ && isMatchingTag($+{tag})).../\}\}\}/ ) {
    if( !// ) {
      print;
      print OUTP if $opt_w;
    }
  }
}

close OUTP if $opt_w;
}

if( -d $opt_i ) {
  $opt_i=File::Spec->catfile($opt_i,'notes.txt');
}
open INPUT, "<", $opt_i or die "Cannot open $opt_i";
if( $opt_l || !@ARGV) {
  list_snippets();
} else {
  extract_snippet(shift());
}
close INPUT;

=head1 OPTIONS

=over

=item -l

list available snippets

=item -i I<filename>

input file name, default C<notes.txt>

=item -w

write contents of embedded file to disk with its nominal name, C<-o> allows to overwrite the name

=item -o I<filename>

In addition to printing contents of a snippet, write it to file. Default name for a file is snippet's internal name.

=item -c

(Not implemented yet!!!)
Normally snippet ends when it encounters C<}}}> anywhere in the text. This
prevents snippets to have contained snippets inside of them. This option
enables such containement: the matching pairs of fold markers will be tracked
and only the closing marker which matches the opening marker for the snippet
will end the snippet.

=item -t I<tag>

List only snippets with a given tag. Tag is case insensitive, consists of alphabetical characters and C<->/C<_>, may include trailing C<:>, but does not have to.

=item -f

alias for C<-t file>

=item -a

alias for C<-t action>

=back

=head1 DESCRIPTION

The file C<notes.txt> in current directory may contain wrapped snippets of smaller files for further use.

Snippets are marked with

    File: filename.txt {{{
    -- file contents
    }}}

=cut
