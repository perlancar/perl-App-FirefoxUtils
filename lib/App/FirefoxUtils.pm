package App::FirefoxUtils;

# AUTHORITY
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

our %argopt_quiet = (
    quiet => {
        schema => 'true*',
        cmdline_aliases => {q=>{}},
    },
);

our %args_common = (
    %argopt_users,
);

sub _do_firefox {
    require Proc::Find;

    my ($which, %args) = @_;

    my $procs = Proc::Find::find_proc(
        detail => 1,
        filter => sub {
            my $p = shift;

            if ($args{users} && @{ $args{users} }) {
                return 0 unless grep { $p->{uid} == $_ } @{ $args{users} };
            }
            return 0 unless $p->{fname} =~ /\A(Web Content|WebExtensions|firefox-bin)\z/;
            log_trace "Found PID %d (cmdline=%s, fname=%s, uid=%d)", $p->{pid}, $p->{cmndline}, $p->{fname}, $p->{uid};
            1;
        },
    );

    my @pids = map { $_->{pid} } @$procs;

    if ($which eq 'ps') {
        return [200, "OK", $procs, {'table.fields'=>[qw/pid uid euid state/]}];
    } elsif ($which eq 'pause') {
        kill STOP => @pids;
        [200, "OK", "", {"func.pids" => \@pids}];
    } elsif ($which eq 'unpause') {
        kill CONT => @pids;
        [200, "OK", "", {"func.pids" => \@pids}];
    } elsif ($which eq 'terminate') {
        kill KILL => @pids;
        [200, "OK", "", {"func.pids" => \@pids}];
    } elsif ($which eq 'is_paused') {
        my $num_stopped = 0;
        my $num_unstopped = 0;
        my $num_total = 0;
        for my $proc (@$procs) {
            $num_total++;
            if ($proc->{state} eq 'stop') { $num_stopped++ } else { $num_unstopped++ }
        }
        my $is_paused = $num_total == 0 ? undef : $num_stopped == $num_total ? 1 : 0;
        my $msg = $num_total == 0 ? "There are no firefox processes" :
            $num_stopped   == $num_total ? "Firefox is paused (all processes are in stop state)" :
            $num_unstopped == $num_total ? "Firefox is NOT paused (all processes are not in stop state)" :
            "Firefox is NOT paused (some processes are not in stop state)";
        return [200, "OK", $is_paused, {
            'cmdline.exit_code' => $is_paused ? 0:1,
            'cmdline.result' => $args{quiet} ? '' : $msg,
        }];
    } else {
        die "BUG: unknown command";
    }
}

$SPEC{ps_firefox} = {
    v => 1.1,
    summary => "List Firefox processes",
    args => {
        %args_common,
    },
};
sub ps_firefox {
    _do_firefox('ps', @_);
}

$SPEC{pause_firefox} = {
    v => 1.1,
    summary => "Pause (kill -STOP) Firefox",
    args => {
        %args_common,
    },
};
sub pause_firefox {
    _do_firefox('pause', @_);
}

$SPEC{unpause_firefox} = {
    v => 1.1,
    summary => "Unpause (resume, continue, kill -CONT) Firefox",
    args => {
        %args_common,
    },
};
sub unpause_firefox {
    _do_firefox('unpause', @_);
}

$SPEC{firefox_is_paused} = {
    v => 1.1,
    summary => "Check whether Firefox is paused",
    description => <<'_',

Firefox is defined as paused if *all* of its processes are in 'stop' state.

_
    args => {
        %args_common,
        %argopt_quiet,
    },
};
sub firefox_is_paused {
    _do_firefox('is_paused', @_);
}

$SPEC{terminate_firefox} = {
    v => 1.1,
    summary => "Terminate  (kill -KILL) Firefox",
    args => {
        %args_common,
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

L<App::VivaldiUtils>
