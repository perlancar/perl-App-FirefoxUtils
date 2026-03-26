package App::FirefoxUtils;

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use Exporter qw(import);

# AUTHORITY
# DATE
# DIST
# VERSION

our @EXPORT_OK = qw(
                       ps_firefox
                       pause_firefox
                       unpause_firefox
                       pause_and_unpause_firefox
                       firefox_has_processes
                       firefox_is_paused
                       firefox_is_running
                       terminate_firefox
                       restart_firefox
                       start_firefox
                       open_firefox_tabs
               );

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
    summary => "Terminate Firefox (by default with -KILL signal)",
    args => {
        %App::BrowserUtils::args_common,
        %App::BrowserUtils::argopt_signal,
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

$SPEC{open_firefox_tabs} = {
    v => 1.1,
    summary => 'Open a list of Firefox tabs, with options',
    args => {
        items => {
            schema => ['array*', {
                min_len => 1,
                of => ['hash*', {
                    keys => {
                        url => 'url*',
                        tags => ['array*', {of=>['str*', min_len=>1]}],
                        container => 'str*',
                        include_by_default => ['bool*', default=>1],
                    },
                    req_keys => ['url'],
                }],
            }],
            req => 1,
        },
        new_window => {
            schema => 'bool*',
            cmdline_aliases => {
                w => {},
                # W = --no-new-window
            },
        },
        shuffle => {
            schema => 'bool*',
        },
        include_any_tags => {
            summary => 'Include all items that have any tag specified',
            schema => ['array*', of=>'str*'],
        },
        include_all_tags => {
            summary => 'Include all items that have ALL tags specified',
            schema => ['array*', of=>'str*'],
        },
        exclude_any_tags => {
            summary => 'Exclude all items that have any tags specified',
            schema => ['array*', of=>'str*'],
        },
        exclude_all_tags => {
            summary => 'Exclude all items that have ALL tags specified',
            schema => ['array*', of=>'str*'],
        },
        query => {
            schema => ['array*', of=>'str*'],
            pos => 0,
            slurpy => 1,
        },
    },
    deps => {
        all => [
            {prog=>'firefox-container'},
        ],
    },
};
sub open_firefox_tabs {
    require IPC::System::Options;
    require List::Util;
    require List::Util::Find;

    my %args = @_;

    my $items = $args{items} or return [400, "Please specify items"];
    @$items or return [400, "Please specify at least one item in items"];

    if ($args{shuffle}) {
        $items = [List::Util::shuffle(@$items)];
    }

    my $j = 0;
  ITEM:
    for my $i (0 .. $#{$items}) {
        my $item = $items->[$i];
        my @ff_args;
        my $env = {};

        # if not included by default, will be included only if specifically matching a filter
        my $include_by_default = $item->{include_by_default} // 1;

        my $match_a_filter = 0;

      FILTER: {
          INCLUDE_ANY_TAGS: {
                last unless $args{include_any_tags} && @{ $args{include_any_tags} };
                do { log_debug "Skipping item %s: does not pass include_any_tags %s", $item, $args{include_any_tags}; next ITEM }
                    unless List::Util::Find::hasanystrs($args{include_any_tags}, @{ $item->{tags} // []});
                $match_a_filter++;
            }
          INCLUDE_ALL_TAGS: {
                last unless $args{include_all_tags} && @{ $args{include_all_tags} };
                do { log_debug "Skipping item %s: does not pass include_all_tags %s", $item, $args{include_all_tags}; next ITEM }
                    unless List::Util::Find::hasallstrs($args{include_all_tags}, @{ $item->{tags} // []});
                $match_a_filter++;
            }
          EXCLUDE_ANY_TAGS: {
                last unless $args{exclude_any_tags} && @{ $args{exclude_any_tags} };
                do { log_debug "Skipping item %s: does not pass exclude_any_tags %s", $item, $args{exclude_any_tags}; next ITEM }
                    if List::Util::Find::hasanystrs($args{exclude_any_tags}, @{ $item->{tags} // []});
                $match_a_filter++;
            }
          EXCLUDE_ALL_TAGS: {
                last unless $args{exclude_all_tags} && @{ $args{exclude_all_tags} };
                do { log_debug "Skipping item %s: does not pass exclude_all_tags %s", $item, $args{exclude_all_tags}; next ITEM }
                    if List::Util::Find::hasallstrs($args{exclude_all_tags}, @{ $item->{tags} // []});
                $match_a_filter++;
            }
          QUERY: {
                last unless $args{query} && @{ $args{query} };
                my $num_positive_queries = 0;
                my $num_negative_queries = 0;
                my $match = 0;
              Q:
                for my $query0 (@{ $args{query} }) {
                    my ($is_negative, $query) = $query0 =~ /\A(-?)(.*)/;
                    $num_positive_queries++ if !$is_negative;
                    $num_negative_queries++ if  $is_negative;

                    if ($item->{url} =~ /$query/i) {
                        if ($is_negative) { goto L1 } else { $match = 1; last Q }
                    }
                    for my $tag (@{ $item->{tags} // [] }) {
                        if ($tag =~ /$query/i) {
                            if ($is_negative) { goto L1 } else { $match = 1; last Q }
                        }
                    }
                    for my $container ($item->{container} // '') {
                        if ($container =~ /$query/i) {
                            if ($is_negative) { goto L1 } else { $match = 1; last Q }
                        }
                    }
                } # for query
                $match++ if $num_positive_queries == 0;
              L1:
                do { log_debug "Skipping item %s: does not pass query %s", $item, $args{query}; next ITEM }
                    unless $match;
                $match_a_filter++;
            } # QUERY
        } # FILTER

        if (!$include_by_default && !$match_a_filter) {
            log_debug "Skipping item %s: not included by default and does not match filter(s)", $item;
            next ITEM;
        }

        if ($j == 0 && $args{new_window}) {
            push @ff_args, "--new-window", $item->{url};
        } else {
            push @ff_args, $item->{url};
        }
        $j++;

        if (defined $item->{container}) {
            $env->{FIREFOX_CONTAINER} = $item->{container};
        }

        log_info "Opening tab %d: %s (%s) ...", $j, $item->{url}, (defined $item->{container} ? "container=$item->{container}" : "");
        IPC::System::Options::system({env=>$env, log=>1}, "firefox-container", @ff_args);
    }

    [200];
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

L<App::BraveUtils>

L<App::ChromeUtils>

L<App::OperaUtils>

L<App::VivaldiUtils>

L<App::BrowserUtils>
