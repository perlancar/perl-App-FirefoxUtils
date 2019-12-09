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

use App::BrowserUtils ();

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to Firefox',
};

$SPEC{ps_firefox} = {
    v => 1.1,
    summary => "List Firefox processes",
    args => {
        %App::BrowserUtils::args_common,
    },
};
sub ps_firefox {
    App::BrowserUtils::_do_browser('ps', 'firefox', @_);
}

$SPEC{pause_firefox} = {
    v => 1.1,
    summary => "Pause (kill -STOP) Firefox",
    args => {
       %App::BrowserUtils::args_common,
    },
};
sub pause_firefox {
    App::BrowserUtils::_do_browser('pause', 'firefox', @_);
}

$SPEC{unpause_firefox} = {
    v => 1.1,
    summary => "Unpause (resume, continue, kill -CONT) Firefox",
    args => {
        %App::BrowserUtils::args_common,
    },
};
sub unpause_firefox {
    App::BrowserUtils::_do_browser('unpause', 'firefox', @_);
}

$SPEC{firefox_is_paused} = {
    v => 1.1,
    summary => "Check whether Firefox is paused",
    description => <<'_',

Firefox is defined as paused if *all* of its processes are in 'stop' state.

_
    args => {
        %App::BrowserUtils::args_common,
        %App::BrowserUtils::argopt_quiet,
    },
};
sub firefox_is_paused {
    App::BrowserUtils::_do_browser('is_paused', 'firefox', @_);
}

$SPEC{terminate_firefox} = {
    v => 1.1,
    summary => "Terminate  (kill -KILL) Firefox",
    args => {
        %App::BrowserUtils::args_common,
    },
};
sub terminate_firefox {
    App::BrowserUtils::_do_browser('terminate', 'firefox', @_);
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

L<App::BrowserUtils>
