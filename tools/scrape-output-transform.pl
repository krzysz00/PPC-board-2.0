#!/usr/bin/env perl
# First, scrape with wget -E -k -p --header "Cookie: foo=bar" -i urls
# URLs have the form /posts/scrape/YYYY/MM[abc]?user_id=N
# Then, point where `posts/scrape` ended up
# If copying assets, remove 'turbolinks:load'
# This assumes we're moving from two levels below / to one level, charge the number of ..s in the regexp below to adjust
use strict;
use warnings;
use 5.022;

use File::Basename;
use File::Path qw(make_path);

if (scalar @ARGV < 2) {
    print "Usage: $0 in_dir out_dir\n";
    exit;
}

my $in_dir = $ARGV[0];
my $out_dir = $ARGV[1];

my @in_files = glob "$in_dir/*/*";

my @out_files = @in_files;
@out_files = map { $_ = s/$in_dir/$out_dir/r; $_ = s/\?user_id=\d+//r; $_; } @out_files;

for my $i (0 .. $#in_files) {
    open(my $in, '<', $in_files[$i]) or die "weird shit wnen reading input $in_files[$i]: $!";
    make_path(dirname($out_files[$i]));
    open(my $out, '>', $out_files[$i]) or die "can't open output file $out_files[$i]: $!";
    my $nav_stripping = 0;
    while (<$in>) {
        next if /<script.*src=".*turbolinks.*\.js.*">/;
        if (/^<nav class="navbar navbar-default">$/) {
            $nav_stripping = 1;
        }
        if (m{^</nav>$}) {
            $nav_stripping = 0;
        }
        next if $nav_stripping;
        s{\.\./\.\./\.\./}{\.\./\.\./};
        s{<a href="http://localhost:3000/posts/(\d+)">}{<a href="#post-$1">};
        s{<a href="http://localhost:3000/posts/new\?parent_id=(\d+)">Reply</a>}{<a href="#post-$1">Link to this</a>};
        s{<a href="(\d{2}[a-c])%3Fuser_id=\d+\.html">}{<a href="$1.html">}g; ## TODO: Test
        print {$out}  $_;
    }
    close $in;
    close $out;
}
