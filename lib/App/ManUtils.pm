package App::ManUtils;

# DATE
# VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
#use Log::Any::IfLOG '$log';

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to man(page)',
};

$SPEC{manwhich} = {
    v => 1.1,
    summary => "Get path to manpage",
    args => {
        pages => {
            'x.name.is_plural' => 1,
            schema => ['array*' => of=>'str*', min_len=>1],
            req    => 1,
            pos    => 0,
            greedy => 1,
            element_completion => sub {
                require Complete::Man;

                my %args = @_;

                # XXX restrict only certain section
                Complete::Man::complete_manpage(
                    word => $args{word},
                );
            },
        },
        all => {
            summary => 'Return all found paths for each page instead of the first one',
            schema => 'bool',
            cmdline_aliases => {a=>{}},
        },
        #section => {
        #},
    },
};
sub manwhich {
    my %args = @_;

    my $pages = $args{pages};
    my $all   = $args{all};

    #my $sect = $args{section};
    #if (defined $sect) {
    #    $sect = [map {/\Aman/ ? $_ : "man$_"} split /\s*,\s*/, $sect];
    #}

    require Filename::Compressed;

    my @res;
    for my $dir (split /:/, ($ENV{MANPATH} // '')) {
        next unless -d $dir;
        opendir my($dh), $dir or next;
        for my $sectdir (readdir $dh) {
            next unless $sectdir =~ /\Aman/;
            #next if $sect && !grep {$sectdir eq $_} @$sect;
            opendir my($dh), "$dir/$sectdir" or next;
            my @files = readdir($dh);
            for my $file (@files) {
                next if $file eq '.' || $file eq '..';
                my $chkres = Filename::Compressed::check_compressed_filename(
                    filename => $file,
                );
                my $name = $chkres ? $chkres->{uncompressed_filename} : $file;
                $name =~ s/\.\w+\z//; # strip section name
                for my $page (@$pages) {
                    if ($page eq $name) {
                        push @res, {
                            page => $page,
                            path => "$dir/$sectdir/$file",
                        };
                        last unless $all;
                    }
                }
            }
        }
    }

    my $res;
    if (@$pages > 1 || $all) {
        $res = \@res;
    } else {
        $res = $res[0]{path};
    }

    [200, "OK", $res];
}

1;
# ABSTRACT:

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to man(page):

#INSERT_EXECS_LIST
