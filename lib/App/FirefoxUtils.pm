package App::FirefoxUtils;

# DATE
# DIST
# VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;


our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to Firefox',
};

our %argopt_users = (
    users => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'user',
        summary => 'Kill Firefox processes of certain users only',
        schema => ['array*', of=>'unix::local_uid*'],
    },
);

sub _do_firefox {
    require Proc::Find;

    my ($which, %args) = @_;

    my $pids = Proc::Find::find_proc(
        filter => sub {
            my $p = shift;

            if ($args{users} && @{ $args{users} }) {
                return 0 unless grep { $p->{uid} == $_ } @{ $args{users} };
            }
            return 0 unless $p->{fname} =~ /\A(Web Content|firefox-bin)\z/;
            log_trace "Found PID %d (cmdline=%s, fname=%s, uid=%d)", $p->{pid}, $p->{cmndline}, $p->{fname}, $p->{uid};
            1;
        },
    );

    if ($which eq 'pause') {
        kill STOP => @$pids;
    } elsif ($which eq 'unpause') {
        kill CONT => @$pids;
    } elsif ($which eq 'terminate') {
        kill KILL => @$pids;
    }
    [200, "OK", "", {"func.pids" => $pids}];
}

$SPEC{pause_firefox} = {
    v => 1.1,
    summary => "Pause (kill -STOP) Firefox",
    args => {
        %argopt_users,
    },
};
sub pause_firefox {
    _do_firefox('pause', @_);
}

$SPEC{unpause_firefox} = {
    v => 1.1,
    summary => "Unpause (resume, continue, kill -CONT) Firefox",
    args => {
        %argopt_users,
    },
};
sub unpause_firefox {
    _do_firefox('unpause', @_);
}

$SPEC{terminate_firefox} = {
    v => 1.1,
    summary => "Terminate  (kill -KILL) Firefox",
    args => {
        %argopt_users,
    },
};
sub terminate_firefox {
    _do_firefox('terminate', @_);
}

1;
# ABSTRACT:

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to Firefox:

#INSERT_EXECS_LIST


=head1 SEE ALSO

Some other CLI utilities related to Firefox: L<dump-firefox-history> (from
L<App::DumpFirefoxHistory>).

L<App::ChromeUtils>

L<App::OperaUtils>
