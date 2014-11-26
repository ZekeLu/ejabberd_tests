%% Spec examples:
%%
%%   {suites, "tests", amp_SUITE}.
%%   {groups, "tests", amp_SUITE, [discovery]}.
%%   {groups, "tests", amp_SUITE, [discovery], {cases, [stream_feature_test]}}.
%%   {cases, "tests", amp_SUITE, [stream_feature_test]}.
%%
%% For more info see:
%% http://www.erlang.org/doc/apps/common_test/run_test_chapter.html#test_specifications

{suites, "tests", presence_SUITE}.
{suites, "tests", privacy_SUITE}.
{suites, "tests", private_SUITE}.
{suites, "tests", shared_roster_SUITE}.
{suites, "tests", sic_SUITE}.
{suites, "tests", sm_SUITE}.
{suites, "tests", system_monitor_SUITE}.
{suites, "tests", vcard_simple_SUITE}.
{suites, "tests", websockets_SUITE}.
{config, ["test.config"]}.
{logdir, "ct_report"}.
{ct_hooks, [ct_tty_hook]}.
