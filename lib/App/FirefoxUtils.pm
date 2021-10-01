package App::FirefoxUtils;

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

# AUTHORITY
# DATE
# DIST
# VERSION

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
    description => $App::BrowserUtils::desc_pause,
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

$SPEC{pause_and_unpause_firefox} = {
    v => 1.1,
    summary => "Pause and unpause Firefox alternately",
    description => $App::BrowserUtils::desc_pause_and_unpause,
    args => {
        %App::BrowserUtils::args_common,
        %App::BrowserUtils::argopt_periods,
    },
};
sub pause_and_unpause_firefox {
    App::BrowserUtils::_do_browser('pause_and_unpause', 'firefox', @_);
}

$SPEC{firefox_has_processes} = {
    v => 1.1,
    summary => "Check whether Firefox has processes",
    args => {
        %App::BrowserUtils::args_common,
        %App::BrowserUtils::argopt_quiet,
    },
};
sub firefox_has_processes {
    App::BrowserUtils::_do_browser('has_processes', 'firefox', @_);
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

$SPEC{firefox_is_running} = {
    v => 1.1,
    summary => "Check whether Firefox is running",
    description => <<'_',

Firefox is defined as running if there are some Firefox processes that are *not*
in 'stop' state. In other words, if Firefox has been started but is currently
paused, we do not say that it's running. If you want to check if Firefox process
exists, you can use `ps_firefox`.

_
    args => {
        %App::BrowserUtils::args_common,
        %App::BrowserUtils::argopt_quiet,
    },
};
sub firefox_is_running {
    App::BrowserUtils::_do_browser('is_running', 'firefox', @_);
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

$SPEC{restart_firefox} = {
    v => 1.1,
    summary => "Restart firefox",
    args => {
        %App::BrowserUtils::argopt_firefox_cmd,
        %App::BrowserUtils::argopt_quiet,
    },
    features => {
        dry_run => 1,
    },
};
sub restart_firefox {
    App::BrowserUtils::restart_browsers(@_, restart_firefox=>1);
}

$SPEC{start_firefox} = {
    v => 1.1,
    summary => "Start firefox if not already started",
    args => {
        %App::BrowserUtils::argopt_firefox_cmd,
        %App::BrowserUtils::argopt_quiet,
    },
    features => {
        dry_run => 1,
    },
};
sub start_firefox {
    App::BrowserUtils::start_browsers(@_, start_firefox=>1);
}

1;
# ABSTRACT:

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to Firefox:

#INSERT_EXECS_LIST


=head1 SEE ALSO

Some other CLI utilities related to Firefox: L<dump-firefox-history> (from
L<App::DumpFirefoxHistory>), L<App::FirefoxMultiAccountContainersUtils>.

L<App::ChromeUtils>

L<App::OperaUtils>

L<App::VivaldiUtils>

L<App::BrowserUtils>
