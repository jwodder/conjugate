#!/usr/bin/perl -w
# This script will create a synopsis of a Latin verb and output it as a LaTeX
# document.
# TO DO:
#  - Generally make the code more efficient and support deponents
#  - Make the code work with & output Unicode characters instead of LaTeX
#    escapes (but support both as input) ?
#  - Add plain text output?
#  - Support outputting complete paradigms
use strict;

sub append($$;$);

my($base, $vowel, $vowel2, $stemTwo, $stemThree, $conj, $trans, $first, $subj, $person, $personal, $passive, $perfect, $sum, $adj);

my $word = qr/[[:alpha:]\\={}]+/;
my $long = qr/\\=\{?\\?([aeio])\{?\}?/i;
my $lineTerm = " \\\\\n";

my %short = ('\\=o'      => 1,
	     'm'         => 1,
	     's'         => 0,
	     't'         => 1,
	     'mus'       => 0,
	     'tis'       => 0,
	     'nt'        => 1,
	     'r'         => 1,
	     'ris/re'    => 0,
	     'tur'       => 0,
	     'mur'       => 0,
	     'min\\=\\i' => 0,
	     'ntur'      => 1,
	     'or'        => 1,
	     'te'        => 0);

print <<EOT;
Enter the four principal parts of the verb you wish to conjugate,
separated by spaces, with macrons denoted LaTeX-style:
Enter `quit' to exit.
EOT

print '> ';
while (<STDIN>) {
 if (/^(($word)([ie]?)\\=o),?\s+\2(e|$long)re,?\s+($word)\\=\{?\\i\{?\}?,?\s+($word)us$/io) { # (\\=ur|\\=\{u\}r)?
  ($first, $base, $vowel, $stemTwo, $stemThree) = ($1, $2, $4, $6, $7);
  $trans = !($stemThree =~ s/(\\=ur|\\=\{u\}r)$//i);
  if ($vowel =~ /^\\=\{?a\}?$/i) {
   $conj = 1;
   $subj = '\\=e';
   $vowel2 = '\\=a';
  } elsif ($vowel =~ /^\\=\{?e\}?$/i) {
   $conj = 2;
   $subj = 'e\\=a';
   $vowel2 = '\\=e';
  } elsif ($vowel =~ /^e$/i) {
   ($conj, $subj, $vowel2) = $3 ? (4, 'i\\=a', 'i\\=e') : (3, '\\=a', '\\=e')
  } elsif ($vowel =~ /^\\=\{?\\i\{?\}?$/i) {
   $conj = 5;
   $subj = 'i\\=a';
   $vowel2 = 'i\\=e';
  } else { die "An error has occurred in parsing the stem vowel.\n" }
  last;
 } elsif (/^($word)\\=\{?o\}?$/io) {
  my $tmp = $1;
  print 'Is the verb a standard first-conjugation verb? (y/n): ';
  if (<STDIN> =~ /^y/i) {
   ($base, $conj, $vowel, $subj, $trans, $stemTwo, $stemThree, $first, $vowel2) = ($tmp, 1, '\\=a', '\\=e', 1, "$tmp\\=av", "$tmp\\=at", "$tmp\\=o", '\\=a');
   last;
  } else { print "Enter the four principal parts.\n" }
 } elsif (/^q(uit)?$/i) { exit }
 elsif ($_ eq "`quit'\n") { print "I didn't mean that literally.\n" }
 else { print "Quid?\n" }
 print '> ';
}

print "In what person & number do you wish to conjugate this verb?\n> ";
my $persno;
my $p1 = qr/(1(st)?|first)(\s*person)?/i;
my $p2 = qr/(2(nd)?|second)(\s*person)?/i;
my $p3 = qr/(3(rd)?|third)(\s*person)?/i;
my $sing = qr/s(ing(\.|ular)?)?/i;
my $plural = qr/p(l(\.|ur(\.|al)?)?)?/i;
while (defined($persno = <STDIN>)) {
 chomp;
 if ($persno =~ /^$p1,?\s*$sing$/io) {
  ($person, $personal, $passive, $perfect, $sum,  $adj) =
  (0,       '\\=o',    'r',      '\\=\\i', 'sum', 'us/a/um')
 } elsif ($persno =~ /^$p2,?\s*$sing$/io) {
  ($person, $personal, $passive, $perfect,    $sum, $adj) =
  (1,      's',       'ris/re',  'ist\\=\\i', 'es', 'us/a/um')
 } elsif ($persno =~ /^$p3,?\s*$sing$/io) {
  ($person, $personal, $passive, $perfect, $sum,  $adj) =
  (2,       't',       'tur',    'it',     'est', 'us/a/um')
 } elsif ($persno =~ /^$p1,?\s*$plural$/io) {
  ($person, $personal, $passive, $perfect, $sum,    $adj) =
  (3,       'mus',     'mur',    'imus',   'sumus', '\\=\\i/ae/a')
 } elsif ($persno =~ /^$p2,?\s*$plural$/io) {
  ($person, $personal, $passive,    $perfect, $sum,    $adj) =
  (4,       'tis',     'min\\=\\i', 'istis',  'estis', '\\=\\i/ae/a')
 } elsif ($persno =~ /^$p3,?\s*$plural$/io) {
  ($person, $personal, $passive, $perfect,   $sum,   $adj) =
  (5,       'nt',      'ntur',   '\\=erunt', 'sunt', '\\=\\i/ae/a')
 } elsif ($persno =~ /^q(uit)?$/i) { exit }
 else {print "Quid?\n> "; next; }
 last;
}

(my $filename = $first) =~ tr/\\={}//d;
open my $file, '>', "$filename.tex";
select $file;

my $head = $trans ? 'cc} & \textbf{Active} & \textbf{Passive} \\\\ \hline\multicolumn{3' : 'c}\multicolumn{2';
print <<EOT;
\\documentclass{article}
\\begin{document}
\\title{Synopsis of \\emph{$first}, $persno}
\\author{\\texttt{conjugate.pl}, v.1.1}
\\maketitle
\\begin{center}
\\begin{tabular}{l$head}{c}{\\textbf{Indicative Mood}} \\\\ \\hline
EOT

print 'Present & ', $base; 
append($vowel, $personal, ($conj>3) ? 2 : 0);
if ($trans) {
 print ' & ', $base;
 append($vowel, ($person==0) ? 'or' : $passive, ($conj>3) ? 2 : 0);
}

print $lineTerm, 'Imperfect & ', $base, $vowel2;
append('b\\=a', $personal, 1);
if ($trans) {
 print ' & ', $base, $vowel2;
 append('b\\=a', $passive);
}

print $lineTerm, 'Future & ', $base;
if ($conj < 3) {
 print $vowel;
 append('bi', $personal);
} else { append(($person==0) ? $subj : $vowel2, $personal, 1) }
if ($trans) {
 print ' & ', $base;
 if ($conj < 3) {
  print $vowel;
  append('bi', ($person==0) ? 'or' : $passive);
 } else { append(($person==0) ? $subj : $vowel2, $passive) }
}

print $lineTerm, 'Perfect & ', $stemTwo, $perfect;
print ' & ', $stemThree, $adj, ' ', $sum if $trans;

print $lineTerm, 'Pluperfect & ', $stemTwo;
append('er\\=a', $personal, 1);
if ($trans) {
 print ' & ', $stemThree, $adj, ' ';
 append('er\\=a', $personal, 1);
}

print $lineTerm, 'Future Perfect & ', $stemTwo;
append('eri', $personal, 4);
if ($trans) {
 print ' & ', $stemThree, $adj, ' ';
 append('eri', $personal);
}

print $lineTerm, '\\multicolumn{', $trans+2, "}{c}{\\textbf{Subjunctive Mood}} \\\\ \\hline\n Present & ", $base;
append($subj, $personal, 1);
if ($trans) {
 print ' & ', $base;
 append($subj, $passive);
}

print $lineTerm, 'Imperfect & ', $base, $vowel;
append('r\\=e', $personal, 1);
if ($trans) {
 print ' & ', $base, $vowel;
 append('r\\=e', $passive);
}

print $lineTerm, 'Perfect & ', $stemTwo;
append('er\\=\\i{}', $personal, 1);
if ($trans) {
 print ' & ', $stemThree, $adj, ' ';
 append('s\\=\\i{}', $personal, 1);
}

print $lineTerm, 'Pluperfect & ', $stemTwo;
append('iss\\=e', $personal, 1);
if ($trans) {
 print ' & ', $stemThree, $adj, ' ';
 append('ess\\=e', $personal, 1);
}

print $lineTerm, '\\multicolumn{', $trans+2, "}{c}{\\textbf{Infinitives}} \\\\ \\hline\n Present & ", $base, $vowel, 're';
print ' & ', $base, ($conj != 3 && $conj != 4) ? ($vowel, 'r\\=\\i') : '\\=\\i' if $trans;

print $lineTerm, 'Perfect & ', $stemTwo, 'isse';
print ' & ', $stemThree, 'us/a/um esse' if $trans;

print $lineTerm, 'Future & ', $stemThree, '\\=urus/a/um esse';
print ' & ---' if $trans;

print $lineTerm, '\\multicolumn{', $trans+2, "}{c}{\\textbf{Participles}} \\\\ \\hline\n Present & ", $base, $vowel2, 'ns, -';
$vowel2 =~ s/\\=//;
print $vowel2, 'ntis';
print ' & ---' if $trans;

print $lineTerm, 'Perfect & ---';
print ' & ', $stemThree, 'us/a/um' if $trans;

print $lineTerm, 'Future & ', $stemThree, '\\=urus/a/um';
print ' & ', $base, $vowel2, 'ndus/a/um' if $trans;

print $lineTerm, '\\multicolumn{', $trans+2, "}{c}{\\textbf{Imperatives}} \\\\ \\hline\n & ", $base, $vowel, ', ', $base;
append($vowel, 'te');
if ($trans) {
 print ' & ', $base, $vowel, 're, ', $base;
 append($vowel, 'min\\=\\i');
}

if ($trans) {
 print <<EOT;
$lineTerm & \\textbf{Gerunds} & \\textbf{Supines} \\\\ \\hline
Genitive & $base${vowel2}nd\\=\\i & --- \\\\
Dative & $base${vowel2}nd\\=o & --- \\\\
Accusative & $base${vowel2}ndum & ${stemThree}um \\\\
Ablative & $base${vowel2}nd\\=o & ${stemThree}\\=u \\\\
EOT
} else {
 print <<EOT;
$lineTerm \\multicolumn{2}{c}{\\textbf{Gerunds}} \\\\ \\hline
Genitive & $base${vowel2}nd\\=\\i \\\\
Dative & $base${vowel2}nd\\=o \\\\
Accusative & $base${vowel2}ndum \\\\
Ablative & $base${vowel2}nd\\=o \\\\
\\multicolumn{2}{c}{\\textbf{Supines}} \\\\ \\hline
Accusative & ${stemThree}um \\\\
Ablative & ${stemThree}\\=u \\\\
EOT
}

print '\\end{tabular}\\end{center}\\end{document}';
close;
select STDOUT;
print "Done!\nThe synopsis has been saved to $filename.tex.\nWould you like to typeset it now? (y/n): ";
if (<STDIN> =~ /^y/i) {
 system("pdflatex $filename.tex");
 system("open $filename.pdf") unless $?;
}

sub append($$;$) {
 my($pre, $post, $opt) = @_;
 # Bits guide for $opt:
 # 1 - Use 'm' instead of '\=o'
 # 2 - Use -i\=o & -iunt endings
 # 4 - Use -int instead of -unt (only applies to fut. perf. act. indic.)
 $opt = 0 if !defined $opt;
 $post = 'm' if $post eq '\\=o' && ($opt & 1);
 if ($pre =~ /$long$/o) {
  $pre =~ s/$long$/$1/o if $short{$post};
  $pre =~ s/i$/iu/i if $post =~ /^nt/ && ($opt & 2);
  $pre =~ s/a$//i if $post =~ /^(\\=)?o/;
 } else {
  $pre =~ s/e$/i/i;
  if ($post =~ /^nt/) {
   if ($opt & 2) { $pre =~ s/i$/iu/ }
   elsif (!($opt & 4)) { $pre =~ s/i$/u/ }
    # 4 applies to the fut. perf. act. indic.
  } elsif ($post =~ /^(\\=)?o/ && !($opt & 2)) { $pre =~ s/i$// }
  elsif ($post eq 'ris/re') { $pre =~ s/i$/e/i }
 }
 print $pre, $post;
}
