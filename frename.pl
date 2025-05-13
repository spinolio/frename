#!/usr/bin/perl

use strict;
use warnings;
use File::Spec;
use Getopt::Long;

my $chars_to_remove = '()';
my $directory = '.';
my $dry_run = 0;
my $help = 0;

GetOptions(
    'chars=s' => \$chars_to_remove,
    'dir=s'   => \$directory,
    'dry-run' => \$dry_run,
    'help|h'  => \$help,
) or usage();

usage() if $help;

# Create a character class for the substitution
my $char_class = '[' . quotemeta($chars_to_remove) . ']';

if (! -d $directory) {
    die "Error: Directory '$directory' not found.\n";
}

print "Processing directory: $directory\n";
print "Characters to remove: '$chars_to_remove'\n";
print "Dry run: " . ($dry_run ? "Yes" : "No") . "\n";

opendir(my $dh, $directory) or die "Cannot open directory '$directory': $!";

my @files = readdir($dh);

closedir($dh);

foreach my $filename (@files) {
    # Skip current and parent directory entries
    next if ($filename eq '.' || $filename eq '..');

    my $original_filepath = File::Spec->catfile($directory, $filename);

    # Only process files, not directories
    next unless (-f $original_filepath);

    my $new_filename = $filename;
    $new_filename =~ s/$char_class//g;
    $new_filename =~ s/\s+/_/g;

    if ($new_filename ne $filename) {
        my $new_filepath = File::Spec->catfile($directory, $new_filename);

        if ($dry_run) {
            print "Dry run: Rename '$filename' to '$new_filename'\n";
        } else {
            if (-e $new_filepath) {
                warn "Skipping rename: Target file '$new_filename' already exists.\n";
            } else {
                if (rename($original_filepath, $new_filepath)) {
                    print "Renamed '$filename' to '$new_filename'\n";
                } else {
                    warn "Error renaming '$filename' to '$new_filename': $!\n";
                }
            }
        }
    }
}

exit(0);

sub usage {
    print <<EOF;
Usage: $0 [options]

Rename files in a directory by removing spaces and specified characters.

Options:
  --chars <characters>  Specify a string of characters to remove from filenames.
                        Spaces are removed by default.
  --dir <directory>     Specify the directory to process (default: current directory).
  --dry-run             Show what would be renamed without actually renaming.
  --help, -h            Print this help message.

Examples:
  $0 --chars "_-" --dir /path/to/your/files
  $0 --chars "[]()"
  $0 --dry-run --dir .
EOF
    exit(1);
}
